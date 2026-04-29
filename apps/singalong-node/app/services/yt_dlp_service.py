"""
YT-DLP Wrapper Service for Node

Provides abstraction for extracting metadata from YouTube URLs
using the yt-dlp command-line tool. This allows Node to identify
songs independently without calling Master for every identification.
"""

import subprocess
import json
import logging
from typing import Optional, Dict

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
            # Run yt-dlp with JUST the video ID (not the full URL)
            # This helps bypass YouTube bot detection
            result = subprocess.run(
                [
                    "yt-dlp",
                    "--dump-json",
                    "--no-warnings",
                    "--socket-timeout",
                    str(self.timeout),
                    video_id,  # Use video ID instead of full URL
                ],
                capture_output=True,
                text=True,
                timeout=self.timeout + 5,
            )

            if result.returncode != 0:
                error_msg = result.stderr or "Unknown error"
                logger.error(f"yt-dlp error: {error_msg}")

                # Parse error to provide better message
                if "is not available" in error_msg or "removed" in error_msg:
                    raise YTDLPError("Video not found or has been removed")
                if "private" in error_msg or "age restricted" in error_msg:
                    raise YTDLPError("Video is private or age-restricted")
                if "throttled" in error_msg:
                    raise YTDLPError("Request throttled by YouTube")

                raise YTDLPError(f"Failed to extract metadata: {error_msg}")

            data = json.loads(result.stdout)

            # Extract and normalize fields
            return {
                "videoId": data.get("id"),
                "title": data.get("title", ""),
                "artist": data.get("uploader", ""),
                "duration": data.get("duration", 0),
                "thumbnail": data.get("thumbnail", ""),
                "year": data.get("release_date", "")[:4]
                if data.get("release_date")
                else "",
                "channel": data.get("uploader", ""),
                "language": data.get("language", ""),
                "description": data.get("description", ""),
                "viewCount": data.get("view_count", 0),
                "url": data.get("webpage_url", url),
            }

        except subprocess.TimeoutExpired:
            logger.error(f"yt-dlp timeout for {url}")
            raise YTDLPError("Request timed out")
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse yt-dlp output: {e}")
            raise YTDLPError("Invalid response format from metadata extractor")
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
