"""
Service for song metadata enhancement using multi-agent orchestration.

The enhancement service uses a coordinated team of OpenAI agents:
1. Extractor Agent: Proposes title/artist from YouTube metadata
2. Researcher Agent: Verifies against MusicBrainz and other sources
3. Validator Agent: Assesses confidence and quality

This orchestration ensures high-accuracy extraction (>50% target).
"""

import logging
from typing import Dict, Any

from app.services.song_enhancement_orchestrator import SongEnhancementOrchestrator

logger = logging.getLogger(__name__)


class EnhancementError(Exception):
    """Base exception for enhancement errors"""
    pass


class EnhancementService:
    """
    Enhance song metadata using multi-agent orchestration.
    
    Uses a team of specialized agents that work together to extract
    accurate title, artist, year, and language information from
    YouTube metadata.
    
    The orchestration approach ensures >50% accuracy by:
    - Multiple extraction attempts with different strategies
    - Cross-validation against music databases
    - Confidence scoring (0-100%) for each result
    - Graceful degradation (returns best guess after N retries)
    """

    # Validation constraints
    MIN_TITLE_LENGTH = 1
    MAX_TITLE_LENGTH = 255
    MIN_ARTIST_LENGTH = 0  # Artist can be empty
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
        Initialize enhancement service with orchestrator.
        
        Args:
            api_key: OpenAI API key for multi-agent orchestration
        """
        self.orchestrator = SongEnhancementOrchestrator(api_key)
        logger.info("EnhancementService initialized with orchestrator")

    async def enhance(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enhance song metadata using multi-agent orchestration.
        
        The orchestrator attempts extraction multiple times to achieve
        >50% confidence. Returns best result (even if confidence is low).
        
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
            Plus metrics: confidence (0-100), match_quality, attempts
            Always returns valid metadata (never None/null).
            Always HTTP 200 OK (enhancement is optional).
        """
        try:
            logger.info(f"Enhancing metadata for: {metadata.get('title', 'unknown')}")
            
            # Use orchestrator to enhance with multi-agent approach
            enhanced, metrics = await self.orchestrator.enhance(metadata)
            
            # Validate enhanced metadata
            validated = self._validate_enhanced(enhanced, metadata)
            
            logger.info(
                f"Enhancement complete: {validated.get('artist', 'N/A')} - {validated.get('title', 'N/A')} "
                f"(confidence: {metrics.get('confidence', 0)}%, attempts: {metrics.get('attempts', 1)})"
            )
            
            # Add metrics to the response (for debugging/monitoring)
            validated['_enhancement_metrics'] = metrics
            
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
            enhanced: Enhanced metadata from orchestrator
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

        # Validate artist (can be empty)
        try:
            artist = str(validated.get("artist") or "")
            if len(artist) > self.MAX_ARTIST_LENGTH:
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
            if key not in validated and key != '_enhancement_metrics':
                validated[key] = original[key]

        return validated

