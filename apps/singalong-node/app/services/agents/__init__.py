"""
Enhancement agents module.

Each agent specializes in extracting or verifying specific metadata fields:
- DescriptionParserAgent: Parse title and artist from YouTube title
- MusicBrainzAgent: Research metadata from MusicBrainz database
- AniDBAgent: Research anime-specific content from AniDB
- LyricsResearchAgent: Fetch lyrics from lyrics.ovh
- LanguageDetectionAgent: Detect song language using textblob/langdetect
"""

from .base import Agent

__all__ = ["Agent"]
