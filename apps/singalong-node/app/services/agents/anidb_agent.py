"""
AniDB Agent - Research anime-specific content from AniDB.

Simplified version: Detects if song is anime-related based on tags/context,
and attempts to find matching anime/soundtrack information.

Note: Full AniDB API requires UDP connection and strict rate limiting.
This simplified version uses heuristics and fallback.
"""

import logging
from typing import Dict, Any

from .base import Agent

logger = logging.getLogger(__name__)


class AniDBAgent(Agent):
    """
    Research anime/soundtrack metadata.
    
    Since full AniDB API requires UDP and complex setup, this uses
    heuristics to detect anime songs and provide context.
    """

    def __init__(self, timeout: int = 5):
        super().__init__(timeout=timeout, name="AniDBAgent")

    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Detect anime/soundtrack context.
        
        Args:
            context: {
                "title": str,
                "artist": str,
                "tags": List[str],
                "description": str (optional)
            }
        
        Returns:
            {
                "anime_detected": bool,
                "confidence": float
            }
        """
        try:
            tags = context.get("tags", [])
            title = context.get("title", "")
            description = context.get("description", "")
            
            # Heuristic: Check for anime indicators in tags/title/description
            is_anime = self._detect_anime(tags, title, description)
            
            if is_anime:
                logger.debug(f"Anime detected: {title}")
                return {
                    "anime_detected": True,
                    "confidence": 0.8
                }
            else:
                return {}
            
        except Exception as e:
            logger.debug(f"AniDBAgent error: {e}")
            return {}

    def _detect_anime(self, tags: list, title: str, description: str) -> bool:
        """
        Detect if song is anime-related using heuristics.
        
        Checks for anime keywords in tags, title, description.
        """
        anime_keywords = {
            "anime", "karaoke", "opening", "ending", "op", "ed",
            "ost", "soundtrack", "japanese", "jp", "日本", "オープニング",
            "エンディング", "カラオケ"
        }
        
        # Check tags
        for tag in tags:
            if tag.lower() in anime_keywords:
                return True
        
        # Check title for anime-specific terms
        title_lower = title.lower()
        for keyword in ["opening", "ending", "op ", "ed ", "ost"]:
            if keyword in title_lower:
                return True
        
        # Check for Japanese characters
        if any('\u4e00' <= c <= '\u9fff' or '\u3040' <= c <= '\u309f' 
               for c in title):
            return True
        
        # Check description
        desc_lower = description.lower() if description else ""
        for keyword in ["anime", "opening", "ending", "ost", "soundtrack"]:
            if keyword in desc_lower:
                return True
        
        return False
