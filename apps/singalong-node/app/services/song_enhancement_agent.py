"""
OpenAI Agent Orchestrator - Uses OpenAI with function calling for song enhancement.

The agent:
1. Receives minimal YouTube metadata (title, tags, description)
2. Decides which research tools to call (MusicBrainz, lyrics, language detection)
3. Iterates until confident in enhanced metadata
4. Returns improved: title, artist, year, language
"""

import json
import logging
from typing import Dict, Any
from openai import AsyncOpenAI

from app.services.research_tools import ResearchTools

logger = logging.getLogger(__name__)


class SongEnhancementAgent:
    """
    OpenAI-powered agent for song metadata enhancement.
    
    Uses gpt-4o-mini for cost-effective reasoning with tool calling.
    """

    TOOLS_SCHEMA = [
        {
            "type": "function",
            "function": {
                "name": "search_musicbrainz",
                "description": "Search MusicBrainz database for recording information (artist, release year, country)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "artist": {
                            "type": "string",
                            "description": "Artist name to search for"
                        },
                        "title": {
                            "type": "string",
                            "description": "Song title to search for"
                        }
                    },
                    "required": ["artist", "title"]
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "search_lyrics",
                "description": "Search lyrics.ovh for song lyrics (helps with language detection)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "artist": {
                            "type": "string",
                            "description": "Artist name"
                        },
                        "title": {
                            "type": "string",
                            "description": "Song title"
                        }
                    },
                    "required": ["artist", "title"]
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "detect_language",
                "description": "Detect language of text (song title, lyrics, etc) - returns ISO 639-1 code",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "text": {
                            "type": "string",
                            "description": "Text to detect language from (title, lyrics, tags, etc)"
                        }
                    },
                    "required": ["text"]
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "parse_title",
                "description": "Parse YouTube title to extract artist and song title using regex patterns",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "title": {
                            "type": "string",
                            "description": "YouTube title to parse"
                        }
                    },
                    "required": ["title"]
                }
            }
        }
    ]

    def __init__(self, api_key: str):
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = "gpt-4o-mini"  # Cost-effective reasoning model
        self.max_iterations = 3  # Prevent infinite loops

    async def enhance(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enhance song metadata using OpenAI agent with function calling.
        
        Args:
            metadata: {
                "title": "YouTube title",
                "artist": "Artist (may be empty)",
                "year": "Year (may be empty)",
                "language": "ISO 639-1 code (may be empty)",
                "tags": ["tag1", "tag2", ...],
                "description": "YouTube description (optional)"
            }
        
        Returns:
            Enhanced metadata with improved title, artist, year, language
        """
        try:
            # Build context for the agent
            context = self._build_context(metadata)
            logger.info(f"Starting enhancement for: {metadata.get('title', 'unknown')}")
            logger.debug(f"Context: {context[:200]}...")
            
            # Start agent loop
            messages = [
                {
                    "role": "user",
                    "content": context
                }
            ]
            
            for iteration in range(self.max_iterations):
                logger.info(f"Enhancement iteration {iteration + 1}/{self.max_iterations}")
                
                # Call OpenAI with tools
                response = await self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    tools=self.TOOLS_SCHEMA,
                    tool_choice="auto"
                )
                
                logger.debug(f"Response finish_reason: {response.choices[0].finish_reason}")
                
                # Check if agent wants to use tools
                if response.choices[0].finish_reason == "stop":
                    # Agent is done, extract final answer
                    logger.info("Agent finished (stop)")
                    return self._extract_answer(
                        response.choices[0].message.content,
                        metadata
                    )
                
                if response.choices[0].finish_reason == "tool_calls":
                    # Process tool calls
                    tool_calls = response.choices[0].message.tool_calls
                    if not tool_calls:
                        break
                    
                    # Add assistant message with tool calls
                    messages.append(response.choices[0].message)
                    
                    # Execute tools and collect results
                    tool_results = []
                    for tool_call in tool_calls:
                        result = await self._execute_tool(
                            tool_call.function.name,
                            json.loads(tool_call.function.arguments)
                        )
                        tool_results.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": json.dumps(result)
                        })
                    
                    # Add tool results to messages
                    messages.extend(tool_results)
                    
                else:
                    # Unexpected finish reason, bail out
                    logger.warning(f"Unexpected finish reason: {response.choices[0].finish_reason}")
                    break
            
            # After max iterations, make final call without tools to extract answer
            logger.info("Max iterations reached, requesting final answer")
            messages.append({
                "role": "user",
                "content": "Now provide your final answer as JSON with title, artist, year, and language fields."
            })
            
            final_response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0
            )
            
            if final_response.choices[0].message.content:
                logger.info("Extracting final answer from agent")
                return self._extract_answer(
                    final_response.choices[0].message.content,
                    metadata
                )
            
            # Fallback: return original metadata
            return metadata
            
        except Exception as e:
            logger.error(f"Agent enhancement error: {e}", exc_info=True)
            return metadata

    def _build_context(self, metadata: Dict[str, Any]) -> str:
        """Build context prompt for the agent"""
        tags_str = ", ".join(metadata.get("tags", [])[:10])
        description = metadata.get("description", "")[:500]
        provided_language = metadata.get("language", "")
        
        return f"""You are a music metadata enhancement agent. Your job is to improve song details using available research tools.

Current YouTube metadata:
- Title: {metadata.get('title', '')}
- Tags: {tags_str}
- Description: {description[:200]}
- Provided Language: {provided_language if provided_language else '(none)'}

Current extracted data:
- Artist: {metadata.get('artist', '')}
- Year: {metadata.get('year', '')}
- Language: {metadata.get('language', '')}

Your task:
1. Use parse_title() to extract artist and title from the YouTube title
2. Use search_musicbrainz() to verify/improve artist, year information
3. Use detect_language() to identify the song's language from title/description
4. Use search_lyrics() to get additional context if needed

IMPORTANT RULES:
- Parse_title gives you the most reliable artist extraction from the YouTube title - trust it
- MusicBrainz returns multiple results sorted by year (earliest first):
  * If "primary" field exists, it's the earliest/original recording
  * If you see multiple results, prefer the earliest year (original release)
  * Only accept results where artist matches parse_title's artist
  * If artist doesn't match, use parse_title's artist and leave year empty
- Always prefer parse_title's title over MusicBrainz if parse_title exists
- For language: If the provided language is already set (like "ja" for Japanese), prefer it over detect_language
- Remove any parenthetical content from titles (e.g., romanization, alternatives)

Return your final answer as JSON with these exact fields:
{{
  "title": "cleaned song title (no parentheses or alternatives)",
  "artist": "artist name or empty string",
  "year": "4-digit year or empty string",
  "language": "ISO 639-1 code (en, ja, ko, etc) or empty string"
}}

Be thorough but efficient. Call tools strategically to improve accuracy."""

    async def _execute_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a research tool"""
        try:
            if tool_name == "search_musicbrainz":
                return await ResearchTools.search_musicbrainz(
                    arguments.get("artist", ""),
                    arguments.get("title", "")
                )
            elif tool_name == "search_lyrics":
                return await ResearchTools.search_lyrics(
                    arguments.get("artist", ""),
                    arguments.get("title", "")
                )
            elif tool_name == "detect_language":
                return await ResearchTools.detect_language(
                    arguments.get("text", "")
                )
            elif tool_name == "parse_title":
                return await ResearchTools.parse_title(
                    arguments.get("title", "")
                )
            else:
                return {"status": "unknown_tool"}
        except Exception as e:
            logger.error(f"Tool execution error ({tool_name}): {e}")
            return {"status": "error", "error": str(e)}

    def _extract_answer(self, response_text: str, original: Dict[str, Any]) -> Dict[str, Any]:
        """Extract enhanced metadata from agent response"""
        try:
            # Try to find JSON in response
            import json
            import re
            
            # Find JSON block
            match = re.search(r'\{[^{}]*"title"[^{}]*\}', response_text)
            if match:
                result = json.loads(match.group())
                # Merge with original to preserve other fields
                enhanced = original.copy()
                enhanced.update({
                    "title": result.get("title", original.get("title", "")),
                    "artist": result.get("artist", original.get("artist", "")),
                    "year": result.get("year", original.get("year", "")),
                    "language": result.get("language", original.get("language", ""))
                })
                return enhanced
        except Exception as e:
            logger.debug(f"Failed to parse agent response: {e}")
        
        # Fallback
        return original
