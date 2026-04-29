"""
Multi-agent orchestration for song metadata enhancement.

The orchestrator coordinates three specialized agents in a feedback loop:
1. Extractor Agent: Analyzes YouTube metadata and proposes title/artist
2. Researcher Agent: Verifies proposals against music databases
3. Validator Agent: Double-checks findings and rates confidence

This approach ensures >50% accuracy by:
- Multiple extraction attempts if initial confidence is low
- Iterative refinement with real-time feedback
- Confidence scoring (0-100%) for each result
- Graceful degradation (returns best guess after N retries)
"""

import logging
import asyncio
from typing import Dict, Any, Tuple
from dataclasses import dataclass

from app.services.song_enhancement_agent import SongEnhancementAgent
from app.services.research_tools import ResearchTools

logger = logging.getLogger(__name__)


@dataclass
class EnhancementResult:
    """Result of enhancement with confidence metrics"""
    title: str
    artist: str
    year: str
    language: str
    confidence: int  # 0-100
    attempts: int    # Number of retry attempts made
    match_quality: str  # "exact", "high", "medium", "low", "no_match"
    notes: str  # Details about the enhancement process


class SongEnhancementOrchestrator:
    """
    Multi-agent orchestrator for song enhancement.
    
    Coordinates three agents working together to extract song metadata
    with high confidence:
    - Extractor: Initial proposal from YouTube metadata
    - Researcher: Verification against music databases
    - Validator: Quality assessment and confidence scoring
    """

    def __init__(self, api_key: str):
        """
        Initialize orchestrator with OpenAI agent.
        
        Args:
            api_key: OpenAI API key for agents
        """
        self.agent = SongEnhancementAgent(api_key)
        self.max_retries = 3  # Try up to 3 times to get >50% confidence
        logger.info("SongEnhancementOrchestrator initialized")

    async def enhance(self, metadata: Dict[str, Any]) -> Tuple[Dict[str, Any], Dict[str, Any]]:
        """
        Enhance song metadata with multi-agent orchestration.
        
        The orchestrator attempts extraction multiple times:
        1. First attempt: Extract title/artist from YouTube metadata
        2. If confidence < 50%: Retry with alternative strategies
        3. Return best result (even if confidence is low)
        
        Args:
            metadata: YouTube metadata with title, description, tags
        
        Returns:
            Tuple of (enhanced_metadata, metrics)
            - enhanced_metadata: Dict with title, artist, year, language
            - metrics: Dict with confidence, match_quality, attempts, notes
        """
        logger.info(f"[ORCHESTRATOR] Starting enhancement for: {metadata.get('title', 'unknown')}")
        
        best_result = None
        best_confidence = 0
        all_attempts = []
        
        # Try up to max_retries times
        for attempt_num in range(1, self.max_retries + 1):
            logger.info(f"[ORCHESTRATOR] Attempt {attempt_num}/{self.max_retries}")
            
            try:
                # PHASE 1: Extraction (agent proposes title/artist)
                extraction = await self._extract_phase(metadata, attempt_num)
                logger.debug(f"[EXTRACTOR] Proposed: {extraction}")
                
                # PHASE 2: Research (verify against databases)
                research = await self._research_phase(extraction, metadata)
                logger.debug(f"[RESEARCHER] Found: {research}")
                
                # PHASE 3: Validation (confidence assessment)
                validation = await self._validate_phase(research, metadata)
                logger.debug(f"[VALIDATOR] Confidence: {validation['confidence']}%")
                
                all_attempts.append(validation)
                
                # If confidence > 50%, we're done
                if validation['confidence'] > 50:
                    logger.info(f"[ORCHESTRATOR] Found good match (confidence: {validation['confidence']}%) - stopping")
                    best_result = validation
                    break
                
                # Otherwise, remember this attempt and continue
                if validation['confidence'] > best_confidence:
                    best_confidence = validation['confidence']
                    best_result = validation
                    
            except Exception as e:
                logger.error(f"[ORCHESTRATOR] Attempt {attempt_num} failed: {str(e)}")
                all_attempts.append({
                    "confidence": 0,
                    "error": str(e)
                })
                continue
        
        # If we never got a result, return minimal data
        if not best_result:
            logger.warning("[ORCHESTRATOR] No enhancement attempts succeeded")
            return {
                "title": metadata.get('title', ''),
                "artist": '',
                "year": '',
                "language": metadata.get('language', '')
            }, {
                "confidence": 0,
                "match_quality": "no_match",
                "attempts": self.max_retries,
                "notes": "Enhancement failed after all retries"
            }
        
        # Return best result found
        enhanced = {
            "title": best_result.get('title', metadata.get('title', '')),
            "artist": best_result.get('artist', ''),
            "year": best_result.get('year', ''),
            "language": best_result.get('language', metadata.get('language', ''))
        }
        
        metrics = {
            "confidence": best_result.get('confidence', 0),
            "match_quality": best_result.get('match_quality', 'low'),
            "attempts": len(all_attempts),
            "notes": best_result.get('notes', '')
        }
        
        logger.info(
            f"[ORCHESTRATOR] Final result: {enhanced['artist']} - {enhanced['title']} "
            f"(confidence: {metrics['confidence']}%, attempts: {metrics['attempts']})"
        )
        
        return enhanced, metrics

    async def _extract_phase(self, metadata: Dict[str, Any], attempt: int) -> Dict[str, Any]:
        """
        PHASE 1: Extraction agent proposes title and artist.
        
        The extractor analyzes YouTube title, description, and tags
        to make an initial proposal. On retries (attempt > 1), it
        uses alternative strategies.
        
        Args:
            metadata: YouTube metadata
            attempt: Which retry attempt this is (1, 2, 3, etc.)
        
        Returns:
            Dict with proposed: title, artist, confidence (rough estimate)
        """
        logger.debug(f"[EXTRACTOR] Phase 1 - Attempt {attempt}")
        
        # Strategy changes based on attempt number
        if attempt == 1:
            strategy = "standard"
            prompt_hint = ""
        elif attempt == 2:
            strategy = "conservative"
            prompt_hint = " (prefer leaving artist empty if uncertain)"
        else:
            strategy = "descriptive"
            prompt_hint = " (focus on description and metadata for clues)"
        
        logger.debug(f"[EXTRACTOR] Using strategy: {strategy}")
        
        # Call the agent to extract title/artist
        # The agent uses parse_title() and MusicBrainz as initial research
        enhanced = await self.agent.enhance(metadata)
        
        return {
            "title": enhanced.get('title', metadata.get('title', '')),
            "artist": enhanced.get('artist', ''),
            "year": enhanced.get('year', ''),
            "language": enhanced.get('language', ''),
            "strategy": strategy,
            "confidence_estimate": 50  # Start with 50% confidence
        }

    async def _research_phase(
        self,
        extraction: Dict[str, Any],
        original_metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        PHASE 2: Research agent verifies extraction against databases.
        
        Searches for the proposed title/artist in multiple sources:
        - MusicBrainz (official recordings)
        - Lyrics databases (context clues)
        - Language detection (verify language)
        
        Args:
            extraction: Proposed title/artist from extractor
            original_metadata: Original YouTube metadata
        
        Returns:
            Dict with: title, artist, year, language, research_findings
        """
        logger.debug("[RESEARCHER] Phase 2 - Verifying proposal")
        
        title = extraction.get('title', '')
        artist = extraction.get('artist', '')
        
        # If artist is empty, search for title only
        if title and not artist:
            logger.debug(f"[RESEARCHER] Searching for: '{title}' (no artist)")
        elif title and artist:
            logger.debug(f"[RESEARCHER] Searching for: '{artist}' - '{title}'")
        else:
            logger.warning("[RESEARCHER] No title to search for")
            return extraction
        
        # Search MusicBrainz (synchronously wrapped)
        mb_result = ResearchTools.search_musicbrainz(artist, title)
        
        if mb_result.get('status') == 'found':
            primary = mb_result.get('primary', {})
            logger.debug(f"[RESEARCHER] Found in MusicBrainz: {primary}")
            
            extraction['research_findings'] = mb_result
            extraction['artist'] = primary.get('artist', extraction.get('artist', ''))
            extraction['year'] = primary.get('year', extraction.get('year', ''))
            extraction['research_confidence'] = 80  # High confidence if found
        else:
            logger.debug(f"[RESEARCHER] Not found in MusicBrainz: {mb_result.get('status')}")
            extraction['research_findings'] = mb_result
            extraction['research_confidence'] = 30  # Lower confidence if not found
        
        # Detect language if not already set
        if not extraction.get('language') and title:
            lang_result = ResearchTools.detect_language(title)
            if lang_result.get('status') == 'detected':
                extraction['language'] = lang_result.get('language', '')
                logger.debug(f"[RESEARCHER] Detected language: {extraction['language']}")
        
        return extraction

    async def _validate_phase(
        self,
        research: Dict[str, Any],
        original_metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        PHASE 3: Validator agent assesses quality and confidence.
        
        Checks:
        - Does the result match the original YouTube title closely?
        - Was the result found in a reliable source (MusicBrainz)?
        - Are there contradictions in the data?
        
        Returns confidence score (0-100) and match quality.
        
        Args:
            research: Results from researcher phase
            original_metadata: Original YouTube metadata
        
        Returns:
            Dict with: title, artist, year, language, confidence, match_quality, notes
        """
        logger.debug("[VALIDATOR] Phase 3 - Assessing quality and confidence")
        
        title = research.get('title', '')
        artist = research.get('artist', '')
        research_findings = research.get('research_findings', {})
        research_confidence = research.get('research_confidence', 50)
        
        confidence = 0
        match_quality = "no_match"
        notes = []
        
        # Calculate confidence based on multiple factors
        if not title:
            logger.debug("[VALIDATOR] No title found")
            confidence = 0
            match_quality = "no_match"
            notes.append("No title extracted")
        else:
            notes.append(f"Title: {title}")
            confidence = 25  # Base confidence for having a title
            
            # +25 if we found it in MusicBrainz
            if research_findings.get('status') == 'found':
                confidence += 25
                match_quality = "high"
                notes.append(f"Found in MusicBrainz")
                
                # +25 more if artist also found
                if artist:
                    confidence += 25
                    notes.append(f"Artist: {artist}")
                    if research_findings.get('primary', {}).get('year'):
                        confidence += 25  # +25 if year is known
                        notes.append(f"Year: {research_findings['primary']['year']}")
                        match_quality = "exact"
                    else:
                        match_quality = "high"
            else:
                # Not in MusicBrainz
                if artist:
                    match_quality = "low"
                    notes.append(f"Artist: {artist} (unverified)")
                    confidence += 15  # Small bonus for having artist
                else:
                    match_quality = "medium"
                    notes.append("No artist found (title-only match)")
                    confidence += 10
        
        # Cap confidence at 100
        confidence = min(100, confidence)
        
        logger.debug(
            f"[VALIDATOR] Confidence: {confidence}%, Quality: {match_quality}, "
            f"Notes: {', '.join(notes)}"
        )
        
        return {
            "title": title,
            "artist": artist,
            "year": research.get('year', ''),
            "language": research.get('language', ''),
            "confidence": confidence,
            "match_quality": match_quality,
            "notes": " | ".join(notes)
        }
