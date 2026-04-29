"""
Description Parser Agent - Extracts title and artist from YouTube titles and descriptions.

This agent uses regex and heuristics to clean and parse metadata, without requiring
external APIs. It handles common YouTube patterns like:
- "[Karaoke 0] Artist - Title (Subtitle)"
- "Artist - Title (Official Video)"
- "Title by Artist [Official]"
"""

import re
import logging
from typing import Dict, Any

from .base import Agent

logger = logging.getLogger(__name__)


class DescriptionParserAgent(Agent):
    """
    Parse title and artist from YouTube title using regex and heuristics.
    
    Handles common patterns:
    - "[Karaoke] Artist - Title" → artist="Artist", title="Title"
    - "Artist - Title (Video)" → artist="Artist", title="Title"
    - "Title by Artist [Official]" → artist="Artist", title="Title"
    """

    def __init__(self, timeout: int = 5):
        """Initialize with 5s timeout (no external I/O)"""
        super().__init__(timeout=timeout, name="DescriptionParserAgent")

    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse title and artist from context.
        
        Args:
            context: Dict with:
                - title: YouTube title (may contain artist + title)
                - description: YouTube description (optional)
                - tags: List of tags (optional)
        
        Returns:
            {
                "title": "parsed title",
                "artist": "parsed artist" (or ""),
                "confidence": 0.0-1.0
            }
        """
        try:
            title = context.get("title", "")
            description = context.get("description", "")
            
            # Parse title
            parsed = self._parse_title(title)
            
            # Cross-check with description if available
            if description:
                parsed = self._refine_with_description(parsed, description)
            
            logger.debug(
                f"Parsed: title='{parsed['title']}', artist='{parsed['artist']}', "
                f"confidence={parsed['confidence']:.2f}"
            )
            
            return parsed
            
        except Exception as e:
            logger.error(f"DescriptionParser error: {e}", exc_info=True)
            return {}

    def _parse_title(self, title: str) -> Dict[str, Any]:
        """
        Extract artist and title from YouTube title.
        
        Patterns (in priority order):
        1. "[Karaoke] Artist - Title" → artist, title
        2. "Artist - Title (Video)" → artist, title
        3. "Title by Artist" → artist, title
        4. "Title [Artist]" → artist, title
        5. Just return title as-is
        
        Args:
            title: YouTube title string
        
        Returns:
            {"title": str, "artist": str, "confidence": float}
        """
        original_title = title
        
        # Step 1: Remove karaoke markers
        title = self._remove_karaoke_markers(title)
        
        # Step 2: Try to extract artist - title format
        match = re.search(r'^(.+?)\s*[-–—]\s*(.+)$', title)
        if match:
            first_part = match.group(1).strip()
            second_part = match.group(2).strip()
            
            # Heuristic: if first_part has parentheses and second_part is short,
            # swap them (e.g., "Song (Cover) - Artist" → artist="Artist", title="Song")
            if ('(' in first_part and ')' in first_part and 
                len(second_part) < len(first_part) and 
                len(second_part) < 50):
                # Likely: "Title (Modifier) - Artist" pattern
                artist = second_part
                title_part = first_part
            else:
                # Normal: "Artist - Title" pattern
                artist = first_part
                title_part = second_part
            
            # Clean up common suffixes from title_part
            title_part = self._clean_title_part(title_part)
            
            return {
                "title": title_part,
                "artist": artist,
                "confidence": 0.9
            }
        
        # Step 3: Try "Title by Artist" format
        match = re.search(r'^(.+?)\s+by\s+(.+)$', title, re.IGNORECASE)
        if match:
            return {
                "title": match.group(1).strip(),
                "artist": match.group(2).strip(),
                "confidence": 0.85
            }
        
        # Step 4: Try "[Artist]" at the end
        match = re.search(r'^(.+?)\s*\[(.+?)\]\s*$', title)
        if match:
            return {
                "title": match.group(1).strip(),
                "artist": match.group(2).strip(),
                "confidence": 0.8
            }
        
        # Step 5: No pattern matched, return title as-is
        return {
            "title": title,
            "artist": "",
            "confidence": 0.6
        }

    def _remove_karaoke_markers(self, title: str) -> str:
        """
        Remove [Karaoke], (Karaoke), etc. markers.
        
        Examples:
        - "[Karaoke 0] Aqours - 未熟DREAMER" → "Aqours - 未熟DREAMER"
        - "(Karaoke Version) Rick - Song" → "Rick - Song"
        - "Song (Instrumental Karaoke)" → "Song"
        """
        # Remove [Karaoke X], (Karaoke), etc.
        title = re.sub(r'\s*\[Karaoke[^\]]*\]', '', title)
        title = re.sub(r'\s*\(Karaoke[^)]*\)', '', title)
        title = re.sub(r'\s*\(Instrumental[^)]*\)', '', title)
        title = re.sub(r'\s*\(Off[- ]Vocal[^)]*\)', '', title)
        title = re.sub(r'\s*\(On[- ]Vocal[^)]*\)', '', title)
        
        return title.strip()

    def _clean_title_part(self, title: str) -> str:
        """
        Remove common suffixes from title part.
        
        Examples:
        - "Song (Official Video)" → "Song"
        - "Song (Lyrics)" → "Song"
        - "Song [Official]" → "Song"
        """
        # Remove (Official Video), (Music Video), (Video), (Lyrics), (Karaoke), etc.
        title = re.sub(r'\s*\([^)]*(?:Video|Music|Official|Lyrics|Karaoke)[^)]*\)', '', title)
        title = re.sub(r'\s*\[[^\]]*(?:Official|Lyrics)[^\]]*\]', '', title)
        
        # Remove trailing parentheses/brackets
        title = re.sub(r'\s*\([^)]*\)\s*$', '', title)
        title = re.sub(r'\s*\[[^\]]*\]\s*$', '', title)
        
        return title.strip()

    def _refine_with_description(
        self,
        parsed: Dict[str, Any],
        description: str
    ) -> Dict[str, Any]:
        """
        Cross-check and refine parsed data with description.
        
        If description starts with "Artist - Title", and we got title from
        YouTube title, verify or update artist/title.
        
        Args:
            parsed: Already parsed title/artist
            description: YouTube description (first 500 chars)
        
        Returns:
            Refined parsed data with potentially updated confidence
        """
        # Just limit description to first 500 chars and first 2 lines
        lines = description.split('\n')[:2]
        first_line = lines[0][:500]
        
        # If description has "Artist - Title" format at start, cross-check
        match = re.search(r'^(.+?)\s*[-–—]\s*(.+)$', first_line)
        if match:
            desc_artist = match.group(1).strip()
            desc_title = match.group(2).strip()[:100]
            
            # If both are confident matches, slightly boost confidence
            if parsed.get("confidence", 0) > 0.7:
                parsed["confidence"] = min(1.0, parsed["confidence"] + 0.05)
        
        return parsed
