"""
Lyrics Research Agent - Fetches song lyrics from lyrics.ovh (completely free).

lyrics.ovh is a free API with no key required, no rate limits (reasonable).
Covers most popular songs (English, Japanese, etc).
"""

import asyncio
import logging
from typing import Dict, Any

import aiohttp

from .base import Agent

logger = logging.getLogger(__name__)

LYRICS_API = "https://api.lyrics.ovh/v1"


class LyricsResearchAgent(Agent):
    """
    Fetch song lyrics from lyrics.ovh API (free, no key required).
    
    Returns lyrics text or empty string if not found.
    """

    def __init__(self, timeout: int = 10):
        super().__init__(timeout=timeout, name="LyricsResearchAgent")

    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Fetch lyrics for song.
        
        Args:
            context: {"title": str, "artist": str}
        
        Returns:
            {"lyrics": "...full lyrics text..." or ""}
        """
        try:
            title = context.get("title", "")
            artist = context.get("artist", "")
            
            if not artist or not title:
                return {}
            
            result = await self._fetch_lyrics(artist, title)
            return result
            
        except Exception as e:
            logger.debug(f"LyricsResearchAgent error: {e}")
            return {}

    async def _fetch_lyrics(self, artist: str, title: str) -> Dict[str, Any]:
        """Fetch lyrics from lyrics.ovh API"""
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{LYRICS_API}/{artist}/{title}"
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        lyrics = data.get("lyrics", "")
                        if lyrics:
                            return {"lyrics": lyrics}
                    return {}
        except Exception as e:
            logger.debug(f"Lyrics fetch error: {e}")
            return {}
