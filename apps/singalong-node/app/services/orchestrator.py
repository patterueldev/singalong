"""
Enhancement Orchestrator - coordinates all agents and merges their results.

The orchestrator is responsible for:
1. Running agents in parallel (parser runs first, then others)
2. Merging results with priority-based conflict resolution
3. Validating merged results
4. Gracefully handling agent failures (skip failed agents)
"""

from typing import Dict, Any
import asyncio
import logging

from .agents.description_parser import DescriptionParserAgent
from .agents.musicbrainz_agent import MusicBrainzAgent
from .agents.anidb_agent import AniDBAgent
from .agents.lyrics_research import LyricsResearchAgent
from .agents.language_detection import LanguageDetectionAgent

logger = logging.getLogger(__name__)


class EnhancementOrchestrator:
    """
    Coordinates all enhancement agents and merges their results.
    """

    def __init__(self):
        """Initialize orchestrator with all agents"""
        self.agents = {
            "parser": DescriptionParserAgent(),
            "musicbrainz": MusicBrainzAgent(),
            "anidb": AniDBAgent(),
            "lyrics": LyricsResearchAgent(),
            "language": LanguageDetectionAgent(),
        }
        logger.info("EnhancementOrchestrator initialized with 5 agents")
        
    async def enhance(self, original_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Enhance metadata using all agents"""
        try:
            # Step 1: Run parser first
            parser_result = await asyncio.wait_for(
                self.agents["parser"].execute(original_metadata),
                timeout=self.agents["parser"].timeout
            )
            
            # Step 2: Run other agents in parallel
            other_results = await asyncio.gather(
                asyncio.wait_for(
                    self.agents["musicbrainz"].execute({**original_metadata, **parser_result}),
                    timeout=self.agents["musicbrainz"].timeout
                ),
                asyncio.wait_for(
                    self.agents["anidb"].execute({**original_metadata, **parser_result}),
                    timeout=self.agents["anidb"].timeout
                ),
                asyncio.wait_for(
                    self.agents["lyrics"].execute({**original_metadata, **parser_result}),
                    timeout=self.agents["lyrics"].timeout
                ),
                asyncio.wait_for(
                    self.agents["language"].execute({**original_metadata, **parser_result}),
                    timeout=self.agents["language"].timeout
                ),
                return_exceptions=True
            )
            
            # Handle exceptions
            mb_result, anidb_result, lyrics_result, lang_result = [
                r if not isinstance(r, Exception) else {} for r in other_results
            ]
            
            # Step 3: Merge results
            merged = self._merge_results(
                original_metadata,
                parser_result,
                mb_result,
                lyrics_result,
                lang_result
            )
            
            # Step 4: Validate
            validated = self._validate(merged, original_metadata)
            
            return validated
            
        except Exception as e:
            logger.error(f"Orchestration error: {e}", exc_info=True)
            return original_metadata

    def _merge_results(
        self,
        original: Dict[str, Any],
        parser_result: Dict[str, Any],
        mb_result: Dict[str, Any],
        lyrics_result: Dict[str, Any],
        lang_result: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Merge results from all agents"""
        merged = original.copy()
        
        # Title: Prefer parser
        if parser_result.get("title"):
            merged["title"] = parser_result["title"]
        
        # Artist: MusicBrainz > Parser
        if mb_result.get("artist"):
            merged["artist"] = mb_result["artist"]
        elif parser_result.get("artist"):
            merged["artist"] = parser_result["artist"]
        
        # Year: MusicBrainz
        if mb_result.get("year"):
            merged["year"] = mb_result["year"]
        
        # Language: MusicBrainz > LanguageDetection
        if mb_result.get("language"):
            merged["language"] = mb_result["language"]
        elif lang_result.get("language"):
            merged["language"] = lang_result["language"]
        
        # Lyrics
        if lyrics_result.get("lyrics"):
            merged["lyrics"] = lyrics_result["lyrics"]
        else:
            merged["lyrics"] = merged.get("lyrics", "")
        
        return merged

    def _validate(
        self,
        metadata: Dict[str, Any],
        original: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Validate merged results"""
        validated = metadata.copy()
        
        # Title
        try:
            title = str(validated.get("title") or "")
            if not (1 <= len(title) <= 200):
                title = original.get("title", "")
            validated["title"] = title
        except:
            validated["title"] = original.get("title", "")
        
        # Artist
        try:
            artist = str(validated.get("artist") or "")
            if not (0 <= len(artist) <= 100):
                artist = original.get("artist", "")
            validated["artist"] = artist
        except:
            validated["artist"] = original.get("artist", "")
        
        # Year
        try:
            year_str = str(validated.get("year") or "")
            if year_str:
                year_int = int(year_str)
                if not (1900 <= year_int <= 2100):
                    year_str = original.get("year", "")
            validated["year"] = year_str
        except:
            validated["year"] = original.get("year", "")
        
        # Language
        try:
            language = str(validated.get("language") or "")
            if language and not (2 <= len(language) <= 5):
                language = original.get("language", "")
            validated["language"] = language
        except:
            validated["language"] = original.get("language", "")
        
        return validated
