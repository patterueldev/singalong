"""
Service for song metadata enhancement using agent-based orchestration.

The enhancement service coordinates multiple agents that specialize in:
- Parsing metadata from titles/descriptions
- Researching from free databases (MusicBrainz, AniDB)
- Detecting language and extracting lyrics
"""

import logging
from typing import Dict, Any

from ..services.orchestrator import EnhancementOrchestrator

logger = logging.getLogger(__name__)


class EnhancementError(Exception):
    """Base exception for enhancement errors"""
    pass


class EnhancementService:
    """
    Enhance song metadata using agent-based orchestration.
    
    Uses multiple specialized agents to research and verify:
    - Title and artist (DescriptionParser + MusicBrainz)
    - Year and genre (MusicBrainz + AniDB)
    - Language (LanguageDetection)
    - Lyrics (LyricsResearch)
    
    Agents run in parallel with graceful degradation.
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

    def __init__(self):
        """
        Initialize enhancement service with agent orchestrator.
        
        In Phase 1: Orchestrator has no agents, returns original metadata
        In Phase 2: Agents are added and orchestrator coordinates them
        """
        self.orchestrator = EnhancementOrchestrator()
        logger.info("EnhancementService initialized with orchestrator")

    async def enhance(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enhance song metadata using orchestrated agents.
        
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
            Enhanced metadata with improved fields, or original on error.
            Always returns valid metadata (never None/null).
            Always HTTP 200 OK (enhancement is optional).
        
        Examples:
            Input:
            {
                "title": "[Karaoke 0] Aqours - 未熟DREAMER...",
                "artist": "",
                "year": "",
                "language": ""
            }
            
            Output (after agents research):
            {
                "title": "未熟DREAMER",
                "artist": "Aqours",
                "year": "2016",
                "language": "ja"
            }
        """
        try:
            logger.debug(f"Enhancing metadata for: {metadata.get('title', 'unknown')}")
            
            # Use orchestrator to enhance metadata
            enhanced = await self.orchestrator.enhance(metadata)
            
            # Validate enhanced metadata
            validated = self._validate_enhanced(enhanced, metadata)
            
            logger.info(
                f"Enhancement complete for: {metadata.get('title', 'unknown')}",
                extra={"enhanced_fields": list(validated.keys())}
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
            enhanced: Enhanced metadata from agents
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
