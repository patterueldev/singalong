"""Service for song metadata enhancement using OpenAI."""

import json
import logging
from typing import Optional

from openai import OpenAI, APIError, APIConnectionError, RateLimitError

logger = logging.getLogger(__name__)


class EnhancementError(Exception):
    """Base exception for enhancement errors"""

    pass


class EnhancementService:
    """
    Enhance song metadata using OpenAI
    
    Improves: title, artist, year, language
    """

    # Validation constraints
    MIN_TITLE_LENGTH = 1
    MAX_TITLE_LENGTH = 255
    MIN_ARTIST_LENGTH = 1
    MAX_ARTIST_LENGTH = 255
    MIN_YEAR = 1900
    MAX_YEAR = 2100

    # Supported languages (ISO 639-1)
    SUPPORTED_LANGUAGES = {
        "en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh", "ko",
        "ar", "hi", "bn", "pa", "te", "mr", "ta", "gu", "kn", "ml"
    }

    def __init__(self, openai_api_key: Optional[str] = None, timeout: int = 30):
        """
        Initialize OpenAI client for AI enhancement
        
        Args:
            openai_api_key: OpenAI API key (optional if not using AI enhancement)
            timeout: Request timeout in seconds
        """
        self.openai_api_key = openai_api_key
        self.timeout = timeout
        self.model = "gpt-4o-mini"  # Fast, cheap model for metadata extraction
        self.client = None

        if openai_api_key:
            self.client = OpenAI(api_key=openai_api_key)

    async def enhance(
        self,
        title: str,
        artist: str = "",
        year: str = "",
        language: str = "",
        tags: list = None,
        description: str = "",
    ) -> dict:
        """
        Enhance song metadata using OpenAI
        
        Improves: title, artist, year, language
        
        Strategy:
        1. Use title as primary source
        2. Use description for additional context
        3. Use tags for artist/genre/language hints
        4. LLM extracts/improves: title, artist, year, language
        5. Validate and return enhanced metadata
        
        Args:
            title: Song title (from identify)
            artist: Current artist (may be empty)
            year: Current year (may be empty)
            language: Current language (may be empty)
            tags: List of tags from metadata
            description: Video description (may be empty)
        
        Returns:
            Dict with enhanced fields: title, artist, year, language
        
        Raises:
            EnhancementError: If OpenAI not configured
        """
        if not self.client:
            raise EnhancementError("OpenAI API key not configured")

        if tags is None:
            tags = []

        try:
            # Build context for LLM
            context = self._build_context(title, artist, year, language, tags, description)

            # Call OpenAI with structured extraction
            response = await self._call_openai(context)

            # Parse and validate response
            enhanced = self._parse_response(response, title, artist, year, language)

            logger.info(
                f"✓ Enhanced metadata: "
                f"title='{enhanced['title']}', "
                f"artist='{enhanced['artist']}', "
                f"year='{enhanced['year']}', "
                f"language='{enhanced['language']}'"
            )

            return enhanced

        except (APIError, APIConnectionError, RateLimitError) as e:
            logger.warning(f"OpenAI API error: {str(e)}. Returning original metadata.")
            # Graceful degradation: return original if LLM fails
            return {
                "title": title,
                "artist": artist,
                "year": year,
                "language": language,
            }
        except Exception as e:
            logger.error(f"Unexpected error during enhancement: {str(e)}")
            # Graceful degradation
            return {
                "title": title,
                "artist": artist,
                "year": year,
                "language": language,
            }

    def _build_context(
        self,
        title: str,
        artist: str,
        year: str,
        language: str,
        tags: list,
        description: str,
    ) -> str:
        """Build context string for LLM"""
        parts = [f"Title: {title}"]

        if artist:
            parts.append(f"Current Artist: {artist}")

        if year:
            parts.append(f"Current Year: {year}")

        if language:
            parts.append(f"Current Language: {language}")

        if description:
            parts.append(f"Description: {description[:500]}")  # Limit to 500 chars

        if tags:
            parts.append(f"Tags: {', '.join(tags[:20])}")  # Limit to 20 tags

        return "\n".join(parts)

    async def _call_openai(self, context: str) -> dict:
        """
        Call OpenAI to enhance song metadata
        """
        prompt = f"""Enhance song metadata from the following information:

{context}

Return a JSON object with improved values for:
1. "title": Clean song title (remove [Karaoke], (Instrumental), etc. prefixes unless they're essential to the song identity)
2. "artist": Full artist name (not channel name, not "unknown"). Empty string if truly unknown.
3. "year": Release year as number (e.g., 2020). Empty string if unknown.
4. "language": ISO 639-1 language code (en, ja, ko, etc.). Empty string if unknown.

For title:
- Clean up bracketed annotations like [Karaoke 0], (Instrumental), (Off Vocal)
- Keep the actual song name clean
- Keep Unicode characters as-is (Japanese, Chinese, Korean, etc.)
- Example: "[Karaoke 0] Aqours - 未熟DREAMER ( Mijuku DREAMER )" → "Aqours - 未熟DREAMER"

For artist:
- Extract primary artist name
- If multiple artists, list them
- Don't include "(Karaoke)" or "(Instrumental)" in artist name
- If no artist found, return empty string

For year:
- Return ORIGINAL release year, not remaster or upload date
- Try to infer from context clues
- If genuinely unknown, return empty string

For language:
- Return ISO 639-1 code (e.g., "en", "ja", "ko", "zh")
- If multiple languages, return primary one
- If unknown, return empty string

Return ONLY valid JSON, no other text."""

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0,  # Deterministic extraction
                timeout=self.timeout,
            )

            # Parse JSON from response
            content = str(response.choices[0].message.content).strip()

            # Try to extract JSON if wrapped in markdown
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()

            return json.loads(content)

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse OpenAI response as JSON: {e}")
            raise EnhancementError("Invalid JSON response from OpenAI")

    def _parse_response(
        self,
        response: dict,
        original_title: str,
        original_artist: str,
        original_year: str,
        original_language: str,
    ) -> dict:
        """
        Parse and validate LLM response
        
        Ensures all fields are strings and handles invalid values gracefully
        """
        try:
            title = str(response.get("title") or "").strip()
            artist = str(response.get("artist") or "").strip()
            year = str(response.get("year") or "").strip()
            language = str(response.get("language") or "").strip()

            # Validate title
            if not title:
                logger.warning("LLM returned empty title, using original")
                title = original_title
            elif len(title) > self.MAX_TITLE_LENGTH:
                logger.warning(f"Title too long, truncating")
                title = title[: self.MAX_TITLE_LENGTH]

            # Validate year format (should be 4-digit number or empty)
            if year:
                try:
                    year_int = int(year)
                    if year_int < self.MIN_YEAR or year_int > self.MAX_YEAR:
                        logger.warning(f"Invalid year {year_int}, using original")
                        year = original_year
                except ValueError:
                    logger.warning(f"Invalid year format '{year}', using original")
                    year = original_year

            # Validate language code (should be 2-5 chars and in supported list)
            if language:
                if len(language) < 2 or len(language) > 5:
                    logger.warning(f"Invalid language code length '{language}', using original")
                    language = original_language
                elif language not in self.SUPPORTED_LANGUAGES:
                    logger.warning(f"Unsupported language '{language}', using original")
                    language = original_language

            return {
                "title": title,
                "artist": artist,
                "year": year,
                "language": language,
            }

        except Exception as e:
            logger.error(f"Error parsing LLM response: {e}")
            # Return original values if parsing fails
            return {
                "title": original_title,
                "artist": original_artist,
                "year": original_year,
                "language": original_language,
            }
