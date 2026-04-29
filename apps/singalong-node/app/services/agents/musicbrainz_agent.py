"""
MusicBrainz Agent - Researches song metadata from the free MusicBrainz database.

Uses the musicbrainzngs library to:
- Search for recordings by title and artist
- Extract: artist, year, language, genre
- Handle: No results, multiple results, network errors
"""

import asyncio
import logging
from typing import Dict, Any, Optional

import musicbrainzngs

from .base import Agent

logger = logging.getLogger(__name__)

# Set User-Agent for MusicBrainz API
musicbrainzngs.set_useragent(
    "Singalong",
    "1.0"
)


class MusicBrainzAgent(Agent):
    """
    Research song metadata from MusicBrainz database.
    
    Uses musicbrainzngs library to query recordings by title and artist.
    Returns: artist, year, language
    
    MusicBrainz is free, requires no API key, and has excellent coverage
    of both Western and Japanese music (including anime soundtracks).
    """

    def __init__(self, timeout: int = 10):
        """Initialize with 10s timeout for API calls"""
        super().__init__(timeout=timeout, name="MusicBrainzAgent")

    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Search MusicBrainz for song metadata.
        
        Args:
            context: Dict with:
                - title: Song title (from parser or original)
                - artist: Artist name (from parser or empty)
        
        Returns:
            {
                "artist": "verified artist",
                "year": "YYYY" or "",
                "language": "iso-639-1 code" or "",
                "confidence": 0.0-1.0
            }
        """
        try:
            title = context.get("title", "")
            artist = context.get("artist", "")
            
            if not title:
                return {}
            
            logger.debug(f"Searching MusicBrainz: '{title}' by '{artist}'")
            
            # Search with timeout
            result = await self._search_musicbrainz(title, artist)
            
            if result:
                logger.debug(
                    f"Found: {result.get('artist', '')} - {result.get('title', '')}"
                    f" (year={result.get('year', '')}, confidence={result.get('confidence', 0):.2f})"
                )
            
            return result
            
        except Exception as e:
            logger.error(f"MusicBrainzAgent error: {e}", exc_info=True)
            return {}

    async def _search_musicbrainz(
        self,
        title: str,
        artist: str = ""
    ) -> Dict[str, Any]:
        """
        Search MusicBrainz for recording matching title/artist.
        
        Args:
            title: Song title
            artist: Artist name (optional)
        
        Returns:
            {"artist": str, "year": str, "language": str, "confidence": float}
            or empty dict if not found
        """
        try:
            # Build search query
            query = title
            if artist:
                query = f'"{title}" AND artist:"{artist}"'
            else:
                query = f'"{title}"'
            
            # Search in async context
            loop = asyncio.get_event_loop()
            result = await asyncio.to_thread(
                self._blocking_search,
                query
            )
            
            return result
            
        except Exception as e:
            logger.error(f"MusicBrainz search error: {e}", exc_info=True)
            return {}

    def _blocking_search(self, query: str) -> Dict[str, Any]:
        """
        Blocking search call (runs in thread pool).
        
        Args:
            query: MusicBrainz search query
        
        Returns:
            Best matching recording or empty dict
        """
        try:
            # Search recordings by title
            results = musicbrainzngs.search_recordings(query, limit=5)
            
            if not results.get("recording-list"):
                return {}
            
            # Get best match
            best = results["recording-list"][0]
            
            # Extract data from best match
            mb_id = best.get("id", "")
            confidence = float(best.get("score", 0)) / 100.0  # Score is 0-100
            
            # Fetch full recording data for detailed info
            recording = musicbrainzngs.get_recording_by_id(
                mb_id,
                includes=["artists", "releases"]
            )
            
            # Extract artist
            artist_name = ""
            if "credit-phrase" in recording.get("recording", {}):
                artist_name = recording["recording"]["credit-phrase"]
            elif "artist-credit" in recording.get("recording", {}):
                artists = recording["recording"]["artist-credit"]
                if isinstance(artists, list) and artists:
                    artist_name = artists[0].get("name", "")
            
            # Extract year from first release
            year_str = ""
            releases = recording.get("recording", {}).get("release-list", [])
            if releases:
                first_release = releases[0]
                date = first_release.get("date", "")
                if date:
                    year_str = date[:4]  # Extract YYYY from YYYY-MM-DD
            
            # Extract language from first release
            language = ""
            if releases:
                lang_code = releases[0].get("text-representation", {}).get("language", "")
                if lang_code:
                    language = self._normalize_language_code(lang_code)
            
            return {
                "artist": artist_name,
                "year": year_str,
                "language": language,
                "confidence": min(confidence, 0.99)  # Cap at 0.99
            }
            
        except Exception as e:
            logger.error(f"MusicBrainz blocking search error: {e}", exc_info=True)
            return {}

    def _normalize_language_code(self, code: str) -> str:
        """
        Normalize MusicBrainz language code to ISO 639-1.
        
        Args:
            code: Language code (e.g., "jpn", "eng", "zho")
        
        Returns:
            ISO 639-1 code (e.g., "ja", "en", "zh") or empty string
        """
        # Map common 3-letter codes to 2-letter ISO 639-1
        mapping = {
            "jpn": "ja",
            "eng": "en",
            "fre": "fr",
            "deu": "de",
            "spa": "es",
            "ita": "it",
            "por": "pt",
            "rus": "ru",
            "zho": "zh",
            "kor": "ko",
            "ara": "ar",
            "hin": "hi",
            "ben": "bn",
            "pan": "pa",
            "tel": "te",
            "mar": "mr",
            "tam": "ta",
            "guj": "gu",
            "kan": "kn",
            "mal": "ml",
        }
        
        # If already 2 letters, return as-is
        if len(code) == 2:
            return code.lower()
        
        # Convert 3-letter to 2-letter
        return mapping.get(code.lower(), "")
