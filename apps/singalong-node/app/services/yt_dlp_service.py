"""
YT-DLP Wrapper Service for Node

Provides abstraction for extracting metadata from YouTube URLs
using the yt-dlp Python library. This allows Node to identify
songs independently without calling Master for every identification.
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

        Strategy: Extract video ID from URL and pass just the ID to yt-dlp.
        This helps bypass YouTube bot detection, since yt-dlp constructs the URL
        internally rather than using the full URL directly.

        Args:
            url: YouTube URL

        Returns:
            Dict with video metadata (videoId, title, artist, duration, etc.)

        Raises:
            YTDLPError: If extraction fails
        """
        if not self.validate_url(url):
            raise YTDLPError("Invalid YouTube URL format")

        # Extract video ID from URL (e.g., "dQw4w9WgXcQ" from full URL)
        video_id = self._extract_video_id(url)
        if not video_id:
            raise YTDLPError("Could not extract video ID from URL")

        try:
            # Use yt-dlp Python library directly
            ydl_opts = {
                "quiet": True,
                "no_warnings": True,
                "socket_timeout": self.timeout,
                "extract_flat": False,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(video_id, download=False)

            # Extract and normalize fields
            # Ensure all string fields are non-None (use empty string as default)
            return {
                "videoId": info.get("id"),
                "source": "youtube",
                "title": info.get("title") or "",
                "artist": "",  # Artist not reliably available from YouTube metadata
                "duration": info.get("duration", 0),
                "thumbnail": info.get("thumbnail") or "",
                "year": (info.get("release_date") or "")[:4],
                "language": info.get("language") or "",
                "url": info.get("webpage_url") or url,
                "tags": info.get("tags") or [],
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
        Check if URL is a valid YouTube URL or video ID

        Supports formats:
        - Full URLs: https://youtube.com/watch?v=VIDEO_ID
        - Short URLs: https://youtu.be/VIDEO_ID
        - Plain video ID: VIDEO_ID (11 alphanumeric characters)

        Args:
            url: URL to validate

        Returns:
            True if URL is valid YouTube URL or video ID
        """
        import re

        if not url or not isinstance(url, str):
            return False

        # Check for full/short YouTube URLs
        if "youtube.com" in url or "youtu.be" in url:
            return True

        # Check if it's a plain 11-character video ID
        if re.match(r"^[a-zA-Z0-9_-]{11}$", url):
            return True

        return False

    def _extract_video_id(self, url: str) -> Optional[str]:
        """
        Extract video ID from YouTube URL

        Supports formats:
        - https://www.youtube.com/watch?v=VIDEO_ID
        - https://youtu.be/VIDEO_ID
        - https://youtube.com/watch?v=VIDEO_ID&...

        Args:
            url: YouTube URL

        Returns:
            Video ID string, or None if not found
        """
        import re

        # Pattern 1: youtu.be/VIDEO_ID
        match = re.search(r"youtu\.be/([a-zA-Z0-9_-]{11})", url)
        if match:
            return match.group(1)

        # Pattern 2: youtube.com/watch?v=VIDEO_ID
        match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
        if match:
            return match.group(1)

        # Pattern 3: Maybe it's already just a video ID
        if re.match(r"^[a-zA-Z0-9_-]{11}$", url):
            return url

        return None

    def _get_video_description(self, video_id: str) -> Optional[str]:
        """
        Fetch just the description of a YouTube video
        
        Used for AI enhancement - gets description for context
        
        Args:
            video_id: YouTube video ID
        
        Returns:
            Video description string, or None if not available
        """
        try:
            ydl_opts = {
                "quiet": True,
                "no_warnings": True,
                "socket_timeout": self.timeout,
                "extract_flat": False,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(video_id, download=False)
                return info.get("description", "")

        except Exception as e:
            logger.warning(f"Error fetching description: {str(e)}")
            return None
