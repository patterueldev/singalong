"""
Service for song metadata enhancement using OpenAI agents.

The enhancement service uses OpenAI with function calling to:
- Parse YouTube titles intelligently
- Research metadata from MusicBrainz, lyrics, language detection
- Iterate until confident in enhanced data
"""

import logging
from typing import Dict, Any

from app.services.song_enhancement_agent import SongEnhancementAgent

logger = logging.getLogger(__name__)


class EnhancementError(Exception):
    """Base exception for enhancement errors"""
    pass


class EnhancementService:
    """
    Enhance song metadata using OpenAI agent with function calling.
    
    The agent coordinates multiple research tools:
    - parse_title: Extract artist and title from YouTube title
    - search_musicbrainz: Verify artist, year from official database
    - detect_language: Identify song language
    - search_lyrics: Get lyrics for language detection context
    
    Agent iterates strategically to improve accuracy.
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

    def __init__(self, api_key: str):
        """
        Initialize enhancement service with OpenAI agent.
        
        Args:
            api_key: OpenAI API key for function calling
        """
        self.agent = SongEnhancementAgent(api_key)
        logger.info("EnhancementService initialized with OpenAI agent")

    async def enhance(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enhance song metadata using OpenAI agent.
        
        Args:
            metadata: Original metadata from identify endpoint:
                - videoId: str
                - source: str (usually "youtube")
                - title: str
                - artist: str (may be empty)
                - duration: int
                - thumbnail: str
                - year: str (may be empty)
                - language: str (may be empty)
                - url: str
                - tags: List[str]
                - description: Optional[str]
        
        Returns:
            Enhanced metadata with improved: title, artist, year, language
            Always returns valid metadata (never None/null).
            Always HTTP 200 OK (enhancement is optional).
        """
        try:
            logger.info(f"Enhancing metadata for: {metadata.get('title', 'unknown')}")
            
            # Use agent to enhance metadata
            enhanced = await self.agent.enhance(metadata)
            
            # Validate enhanced metadata
            validated = self._validate_enhanced(enhanced, metadata)
            
            logger.info(
                f"Enhancement complete: {validated.get('artist', 'N/A')} - {validated.get('title', 'N/A')}"
            )
            
            return validated
            
        except Exception as e:
            logger.error(f"Enhancement error: {e}", exc_info=True)
            # Graceful degradation: return original metadata
            return metadata

    def _validate_enhanced(
        self,
        enhanced: Dict[str, Any],
        original: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Validate enhanced metadata fields.
        
        Ensures:
        - No None/null values (use empty string instead)
        - Field lengths within limits
        - Year in valid range
        - Language in SUPPORTED_LANGUAGES
        
        Invalid fields revert to original values.
        
        Args:
            enhanced: Enhanced metadata from agent
            original: Original metadata (fallback)
        
        Returns:
            Validated metadata (invalid fields use original values)
        """
        validated = enhanced.copy()

        # Validate title
        try:
            title = str(validated.get("title") or original.get("title", ""))
            if not (self.MIN_TITLE_LENGTH <= len(title) <= self.MAX_TITLE_LENGTH):
                title = original.get("title", "")
            validated["title"] = title
        except (TypeError, ValueError):
            validated["title"] = original.get("title", "")

        # Validate artist
        try:
            artist = str(validated.get("artist") or original.get("artist", ""))
            if not (self.MIN_ARTIST_LENGTH <= len(artist) <= self.MAX_ARTIST_LENGTH):
                artist = original.get("artist", "")
            validated["artist"] = artist
        except (TypeError, ValueError):
            validated["artist"] = original.get("artist", "")

        # Validate year
        try:
            year_str = str(validated.get("year") or "")
            if year_str:
                year_int = int(year_str)
                if not (self.MIN_YEAR <= year_int <= self.MAX_YEAR):
                    year_str = original.get("year", "")
            validated["year"] = year_str
        except (TypeError, ValueError):
            validated["year"] = original.get("year", "")

        # Validate language
        try:
            language = str(validated.get("language") or "")
            if language and language not in self.SUPPORTED_LANGUAGES:
                language = original.get("language", "")
            validated["language"] = language
        except (TypeError, ValueError):
            validated["language"] = original.get("language", "")

        # Ensure all fields from original are present
        for key in original:
            if key not in validated:
                validated[key] = original[key]

        return validated
