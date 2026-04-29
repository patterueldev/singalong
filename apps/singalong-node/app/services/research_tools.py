"""
Song Enhancement Tools - Functions that OpenAI agents can call to research metadata.

These tools are called by OpenAI's function calling when the AI decides it needs
additional information to improve song metadata.
"""

import logging
import aiohttp
from typing import Dict, Any, Optional
import asyncio

logger = logging.getLogger(__name__)


class ResearchTools:
    """Tools for researching song metadata"""

    @staticmethod
    async def search_musicbrainz(artist: str, title: str) -> Dict[str, Any]:
        """
        Search MusicBrainz for recording information.
        
        Returns artist, release date, genres.
        """
        try:
            import musicbrainzngs
            musicbrainzngs.set_useragent("Singalong", "1.0")
            
            query = f"{artist} {title}".strip()
            if not query:
                return {"status": "no_query"}
            
            # Search recordings
            result = await asyncio.to_thread(
                musicbrainzngs.search_recordings,
                query=query,
                limit=5
            )
            
            if not result.get("recording-list"):
                return {"status": "not_found"}
            
            # Extract first recording with release info
            for recording in result["recording-list"]:
                if "release-list" in recording and recording["release-list"]:
                    release = recording["release-list"][0]
                    return {
                        "status": "found",
                        "title": recording.get("title", ""),
                        "artist": recording.get("artist-credit-phrase", ""),
                        "year": release.get("date", "")[:4] if release.get("date") else "",
                        "country": release.get("country", ""),
                    }
            
            return {"status": "no_releases"}
            
        except Exception as e:
            logger.debug(f"MusicBrainz search error: {e}")
            return {"status": "error", "error": str(e)}

    @staticmethod
    async def search_lyrics(artist: str, title: str) -> Dict[str, Any]:
        """
        Search lyrics.ovh for song lyrics.
        
        Returns lyrics if found.
        """
        try:
            url = f"https://api.lyrics.ovh/v1/{artist}/{title}"
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        return {
                            "status": "found",
                            "lyrics": data.get("lyrics", "")[:1000]  # First 1000 chars
                        }
                    return {"status": "not_found"}
        except Exception as e:
            logger.debug(f"Lyrics search error: {e}")
            return {"status": "error", "error": str(e)}

    @staticmethod
    async def detect_language(text: str) -> Dict[str, Any]:
        """
        Detect language from text using multiple sources.
        
        Returns ISO 639-1 language code.
        """
        try:
            from langdetect import detect, detect_langs
            
            if not text or len(text) < 3:
                return {"status": "insufficient_text"}
            
            # Get language with confidence
            try:
                lang = detect(text)
                langs = detect_langs(text)
                confidence = next(
                    (l.prob for l in langs if l.lang == lang),
                    0
                )
                return {
                    "status": "detected",
                    "language": lang,
                    "confidence": confidence
                }
            except:
                return {"status": "detection_failed"}
                
        except Exception as e:
            logger.debug(f"Language detection error: {e}")
            return {"status": "error", "error": str(e)}

    @staticmethod
    async def parse_title(title: str) -> Dict[str, Any]:
        """
        Parse YouTube title to extract artist and song title.
        
        Handles patterns like:
        - "Artist - Song Title"
        - "[Karaoke] Artist - Title"
        - "Song (Artist)"
        """
        try:
            import re
            
            title = title.strip()
            
            # Remove karaoke markers
            cleaned = re.sub(
                r'^\[(karaoke|instrumental|cover|remix|remix|acoustic|live|cover|\d+)\][\s-]*',
                '',
                title,
                flags=re.IGNORECASE
            ).strip()
            
            # Pattern 1: "Artist - Title"
            match = re.match(r'^([^-]+?)\s*-\s*(.+)$', cleaned)
            if match:
                artist, song = match.groups()
                return {
                    "status": "parsed",
                    "artist": artist.strip(),
                    "title": song.strip()
                }
            
            # Pattern 2: "Title (Artist)"
            match = re.search(r'^(.+?)\s*\(([^)]+)\)$', cleaned)
            if match:
                title_part, artist_part = match.groups()
                return {
                    "status": "parsed",
                    "title": title_part.strip(),
                    "artist": artist_part.strip()
                }
            
            # Couldn't parse, return original
            return {
                "status": "not_parsed",
                "title": cleaned
            }
            
        except Exception as e:
            logger.debug(f"Title parsing error: {e}")
            return {"status": "error", "error": str(e)}
