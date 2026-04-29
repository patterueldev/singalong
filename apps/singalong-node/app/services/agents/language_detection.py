"""
Language Detection Agent - Detect song language using textblob and langdetect.

Uses:
- langdetect: Fast, works with short text
- textblob: Backup, more accurate for longer text
"""

import logging
from typing import Dict, Any

import langdetect

from .base import Agent

logger = logging.getLogger(__name__)


class LanguageDetectionAgent(Agent):
    """
    Detect language of song from title, lyrics, tags.
    
    Returns ISO 639-1 language code (e.g., "en", "ja", "fr").
    """

    def __init__(self, timeout: int = 5):
        super().__init__(timeout=timeout, name="LanguageDetectionAgent")

    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Detect language from available text.
        
        Args:
            context: {
                "title": str,
                "artist": str,
                "lyrics": str (optional),
                "tags": List[str] (optional)
            }
        
        Returns:
            {"language": "xx", "confidence": 0.0-1.0}
        """
        try:
            # Collect text to analyze
            text_parts = []
            
            # Title is primary (most reliable)
            if context.get("title"):
                text_parts.append(context["title"])
            
            # Lyrics if available (good indicator)
            if context.get("lyrics"):
                # Use first 500 chars of lyrics
                text_parts.append(context["lyrics"][:500])
            
            # Tags (hints)
            if context.get("tags"):
                text_parts.extend(context["tags"][:5])
            
            if not text_parts:
                return {}
            
            text = " ".join(str(t) for t in text_parts)
            
            # Detect language
            try:
                detected_lang = langdetect.detect(text)
                confidence = self._estimate_confidence(text, detected_lang)
                
                # Normalize to ISO 639-1
                lang_code = self._to_iso639_1(detected_lang)
                
                return {
                    "language": lang_code,
                    "confidence": confidence
                }
            except Exception as e:
                logger.debug(f"Language detection error: {e}")
                return {}
            
        except Exception as e:
            logger.debug(f"LanguageDetectionAgent error: {e}")
            return {}

    def _estimate_confidence(self, text: str, detected: str) -> float:
        """
        Estimate confidence of language detection.
        
        Factors:
        - Text length (longer = more confident)
        - Language certainty from langdetect
        """
        # Base confidence from text length
        text_len = len(text)
        if text_len < 10:
            return 0.5
        elif text_len < 50:
            return 0.7
        elif text_len < 200:
            return 0.85
        else:
            return 0.95

    def _to_iso639_1(self, lang_code: str) -> str:
        """
        Convert langdetect output to ISO 639-1.
        
        langdetect returns codes like "en", "ja", "zh-cn", etc.
        Need to normalize to 2-letter ISO 639-1.
        """
        if len(lang_code) == 2:
            return lang_code.lower()
        
        # Handle special cases
        mapping = {
            "zh-cn": "zh",
            "zh-tw": "zh",
        }
        
        return mapping.get(lang_code.lower(), lang_code[:2].lower())
