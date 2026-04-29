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
        
        Returns multiple results sorted by release date (earliest first).
        Agent can then pick the best match based on artist and year consistency.
        """
        try:
            import musicbrainzngs
            musicbrainzngs.set_useragent("Singalong", "1.0")
            
            if not artist or not title:
                return {"status": "no_query"}
            
            # First try: search with both artist and title explicitly
            # MusicBrainz search syntax: arid: artist ID, recording: title
            query = f'recording:"{title}" artist:"{artist}"'
            
            result = await asyncio.to_thread(
                musicbrainzngs.search_recordings,
                query=query,
                limit=10
            )
            
            # If no results, try simpler query
            if not result.get("recording-list"):
                query = f"{artist} {title}"
                result = await asyncio.to_thread(
                    musicbrainzngs.search_recordings,
                    query=query,
                    limit=10
                )
            
            if not result.get("recording-list"):
                return {"status": "not_found"}
            
            # Collect all recordings with release info
            matches = []
            for recording in result["recording-list"]:
                if "release-list" in recording and recording["release-list"]:
                    for release in recording["release-list"]:
                        year = release.get("date", "")[:4] if release.get("date") else ""
                        recording_artist = recording.get("artist-credit-phrase", "")
                        matches.append({
                            "title": recording.get("title", ""),
                            "artist": recording_artist,
                            "year": year,
                            "country": release.get("country", ""),
                        })
            
            if not matches:
                return {"status": "no_releases"}
            
            # Sort by year (earliest first) to prioritize originals
            matches.sort(key=lambda x: x.get("year", "9999"))
            
            return {
                "status": "found",
                "results": matches[:5],  # Return top 5 results (earliest first)
                "primary": matches[0],  # Primary result (earliest/original)
            }
            
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
                # Clean up title: remove parenthetical content (romanization alternatives)
                song = re.sub(r'\s*\([^)]*\)\s*$', '', song).strip()
                return {
                    "status": "parsed",
                    "artist": artist.strip(),
                    "title": song
                }
            
            # Pattern 2: "Title (Artist)"
            match = re.search(r'^(.+?)\s*\(([^)]+)\)$', cleaned)
            if match:
                title_part, artist_part = match.groups()
                # Clean up title: remove parenthetical content
                title_part = re.sub(r'\s*\([^)]*\)\s*$', '', title_part).strip()
                return {
                    "status": "parsed",
                    "title": title_part,
                    "artist": artist_part.strip()
                }
            
            # Couldn't parse, return original
            cleaned_title = re.sub(r'\s*\([^)]*\)\s*$', '', cleaned).strip()
            return {
                "status": "not_parsed",
                "title": cleaned_title
            }
            
        except Exception as e:
            logger.debug(f"Title parsing error: {e}")
            return {"status": "error", "error": str(e)}
