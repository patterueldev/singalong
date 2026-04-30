"""
YT-DLP Wrapper Service

Provides centralized abstraction for all yt-dlp operations: metadata extraction
and video downloading from YouTube using the yt-dlp Python library.
"""

import os
import logging
from typing import Optional, Dict, Tuple, Any
import yt_dlp
import re

logger = logging.getLogger(__name__)


class YTDLPError(Exception):
    """Raised when yt-dlp operation fails"""
    pass


class YTDLPService:
    """Single source of truth for all yt-dlp operations"""

    # Default yt-dlp options used for all operations
    DEFAULT_OPTS = {
        "quiet": True,  # Keep quiet in production
        "no_warnings": True,  # Suppress warnings
        "socket_timeout": 30,
        "verbose": False,  # Turn off verbose logging
    }

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
            ydl_opts = {**self.DEFAULT_OPTS, "extract_flat": False}

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
            logger.error(f"yt-dlp extraction error: {error_msg}")
            raise YTDLPError(self._parse_error_message(error_msg))

            raise YTDLPError(str(e))

    def _get_available_formats(self, video_id: str) -> Dict[str, Any]:
        """
        Extract all available formats for a video without downloading.

        Args:
            video_id: YouTube video ID

        Returns:
            Dict mapping format_id → format_info

        Raises:
            YTDLPError: If format extraction fails
        """
        try:
            logger.debug(f"Extracting available formats for {video_id}...")
            ydl_opts = {**self.DEFAULT_OPTS, "extract_flat": False}

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(video_id, download=False)

            # Build format dict: {format_id: format_info}
            formats = {}
            if "formats" in info:
                for fmt in info["formats"]:
                    format_id = fmt.get("format_id", "")
                    if format_id:
                        formats[format_id] = fmt

            logger.debug(f"  → Found {len(formats)} formats available")
            return formats

        except Exception as e:
            logger.error(f"Error extracting formats: {str(e)}")
            return {}

    def download_video(
        self, video_id: str, output_path: str
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Download video from YouTube and save to specified path.

        Uses yt-dlp's intelligent format selector that:
        - Prefers MP4 video container with H.264/H.265 codecs
        - Pairs with M4A audio (MP4-compatible)
        - Falls back to best available if MP4 combo not available
        - Capped at 1080p maximum resolution
        - yt-dlp automatically merges and handles all protocols (https, HLS, DASH)

        Format logic:
        1. Try: bestvideo[mp4,≤1080p] + bestaudio[m4a]  → High quality MP4
        2. Fall back to: best[≤1080p] → Most compatible

        Args:
            video_id: YouTube video ID (not URL)
            output_path: Full file path where video should be saved

        Returns:
            Tuple of (actual_file_path, error_message)
            - If successful: (path_to_downloaded_file, None)
            - If failed: (None, error_message)
        """
        try:
            logger.info(f"▶ [DOWNLOAD] Starting for video ID: {video_id}")
            logger.debug(f"  → Output path: {output_path}")
            
            # Smart format selection:
            # - (bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]): 1080p MP4 video + M4A audio
            # - /(best[height<=1080]): Fallback to single best format ≤1080p if above not found
            # yt-dlp automatically merges DASH formats and handles all protocols
            ydl_opts = {
                **self.DEFAULT_OPTS,
                "format": "(bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a])/(best[height<=1080])",
                "outtmpl": output_path,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                logger.debug(f"  → Calling yt-dlp for download...")
                info = ydl.extract_info(video_id, download=True)
                
                # Get actual file path from info
                if 'filepath' in info:
                    actual_path = info['filepath']
                else:
                    actual_path = ydl.prepare_filename(info)
                
                # Verify file exists
                if not os.path.exists(actual_path):
                    raise FileNotFoundError(f"Downloaded file not found at {actual_path}")
                
                file_size = os.path.getsize(actual_path)
                logger.info(f"✓ Download complete: {actual_path}")
                logger.info(f"  File size: {file_size / (1024*1024):.2f} MB")
                return actual_path, None

        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            logger.error(f"✗ Download error: {error_msg}")
            return None, self._parse_error_message(error_msg)

        except Exception as e:
            logger.exception(f"✗ Unexpected error: {str(e)}")
            return None, f"Unexpected error: {str(e)}"

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

    @staticmethod
    def _parse_error_message(error_msg: str) -> str:
        """
        Parse yt-dlp error message and return user-friendly message.

        Args:
            error_msg: Raw error message from yt-dlp

        Returns:
            User-friendly error message
        """
        if "is not available" in error_msg or "removed" in error_msg:
            return "Video not found or has been removed"
        if "private" in error_msg.lower():
            return "Video is private"
        if "age-restricted" in error_msg.lower() or "age restricted" in error_msg:
            return "Video is age-restricted"
        if "throttled" in error_msg:
            return "Request throttled by YouTube"
        if "Requested format is not available" in error_msg:
            return "Requested video format not available"
        return f"Download failed: {error_msg}"
