"""
YT-DLP Wrapper Service

Provides abstraction for extracting metadata and downloading videos from YouTube
using the yt-dlp Python library.
"""

import logging
from typing import Optional, Dict
import yt_dlp

logger = logging.getLogger(__name__)


class YTDLPError(Exception):
    """Raised when yt-dlp operation fails"""
    pass


class YTDLPService:
    """Wrapper for yt-dlp command-line tool"""

    def __init__(self, timeout: int = 30):
        """
        Initialize YT-DLP service

        Args:
            timeout: Default timeout in seconds for operations
        """
        self.timeout = timeout

    def extract_metadata(self, url: str) -> Dict:
        """
        Extract metadata from YouTube URL

        Args:
            url: YouTube URL

        Returns:
            Dict with video metadata (videoId, title, artist, duration, etc.)

        Raises:
            YTDLPError: If extraction fails
        """
        if not self.validate_url(url):
            raise YTDLPError("Invalid YouTube URL format")

        try:
            # Use yt-dlp Python library directly
            ydl_opts = {
                "quiet": True,
                "no_warnings": True,
                "socket_timeout": self.timeout,
                "extract_flat": False,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)

            # Extract and normalize fields
            return {
                "videoId": info.get("id"),
                "title": info.get("title", ""),
                "artist": info.get("uploader", ""),
                "duration": info.get("duration", 0),
                "thumbnail": info.get("thumbnail", ""),
                "year": info.get("release_date", "")[:4]
                if info.get("release_date")
                else "",
                "channel": info.get("uploader", ""),
                "language": info.get("language", ""),
                "description": info.get("description", ""),
                "viewCount": info.get("view_count", 0),
                "url": info.get("webpage_url", url),
            }

        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            logger.error(f"yt-dlp download error: {error_msg}")

            # Parse error to provide better message
            if "is not available" in error_msg or "removed" in error_msg:
                raise YTDLPError("Video not found or has been removed")
            if "private" in error_msg or "age restricted" in error_msg:
                raise YTDLPError("Video is private or age-restricted")
            if "throttled" in error_msg:
                raise YTDLPError("Request throttled by YouTube")

            raise YTDLPError(f"Failed to extract metadata: {error_msg}")

        except Exception as e:
            logger.error(f"Unexpected error extracting metadata: {str(e)}")
            raise YTDLPError(str(e))

    def validate_url(self, url: str) -> bool:
        """
        Check if URL is a valid YouTube URL

        Args:
            url: URL to validate

        Returns:
            True if URL is valid YouTube URL
        """
        if not url or not isinstance(url, str):
            return False
        return "youtube.com" in url or "youtu.be" in url
