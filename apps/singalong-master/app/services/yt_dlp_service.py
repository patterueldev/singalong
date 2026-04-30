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
        "quiet": True,
        "no_warnings": True,
        "socket_timeout": 30,
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

    def _score_format(self, format_info: Dict) -> int:
        """
        Score a format based on selection criteria.

        Scoring logic:
        - Skip storyboard, audio-only, and video-only formats
        - Prefer MP4 container (100 pts) over WebM (50 pts)
        - Prefer higher resolution, capped at 1080p:
          * 1080p: 30 pts, 720p: 20 pts, 480p: 10 pts, 360p: 5 pts
        - Must have both video codec (vcodec) and audio codec (acodec)

        Args:
            format_info: Format metadata dict from yt-dlp

        Returns:
            Score (higher is better), or 0 if format is unsuitable
        """
        score = 0

        # Get key fields
        format_id = format_info.get("format_id", "")
        ext = format_info.get("ext", "")
        vcodec = format_info.get("vcodec", "none")
        acodec = format_info.get("acodec", "none")
        height = format_info.get("height", 0)

        # Skip storyboard formats
        if format_id.startswith("sb"):
            logger.debug(f"    Skipping {format_id} (storyboard)")
            return 0

        # Skip audio-only formats (no video codec)
        if vcodec == "none":
            logger.debug(f"    Skipping {format_id} (audio-only)")
            return 0

        # Skip video-only formats (no audio codec)
        if acodec == "none":
            logger.debug(f"    Skipping {format_id} (video-only)")
            return 0

        # Score container type
        if ext == "mp4":
            score += 100
        elif ext == "webm":
            score += 50
        else:
            score += 25

        # Score resolution (prefer up to 1080p)
        if height >= 1080:
            score += 30
        elif height >= 720:
            score += 20
        elif height >= 480:
            score += 10
        elif height >= 360:
            score += 5
        elif height > 0:
            score += 1

        logger.debug(
            f"    Format {format_id}: {ext} {height}p "
            f"({vcodec}/{acodec}) → score: {score}"
        )

        return score

    def _select_best_format(self, video_id: str) -> str:
        """
        Intelligently select the best format for a video.

        Selection criteria:
        1. Must have both video + audio (no video-only or audio-only)
        2. Prefer MP4 over WebM
        3. Prefer highest resolution up to 1080p

        Args:
            video_id: YouTube video ID

        Returns:
            Format ID to use for download, or "best" as fallback
        """
        logger.debug(f"Selecting best format for {video_id}...")

        formats = self._get_available_formats(video_id)
        if not formats:
            logger.warning(f"  ! No formats extracted, falling back to 'best'")
            return "best"

        # Score all formats
        best_format_id = None
        best_score = -1

        logger.debug("  → Scoring available formats:")
        for format_id, format_info in formats.items():
            score = self._score_format(format_info)
            if score > best_score:
                best_score = score
                best_format_id = format_id

        # Return best format or fallback
        if best_format_id:
            logger.debug(
                f"  ✓ Selected format: {best_format_id} (score: {best_score})"
            )
            return best_format_id
        else:
            logger.warning(f"  ! No suitable format found, falling back to 'best'")
            return "best"

    def download_video(
        self, video_id: str, output_path: str
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Download video from YouTube and save to specified path.

        Args:
            video_id: YouTube video ID (not URL)
            output_path: Full file path where video should be saved

        Returns:
            Tuple of (actual_file_path, error_message)
            - If successful: (path_to_downloaded_file, None)
            - If failed: (None, error_message)
        """
        try:
            # Use smart format selection instead of "best"
            selected_format = self._select_best_format(video_id)
            logger.debug(
                f"Starting download for video ID: {video_id} with format: {selected_format}"
            )
            logger.debug(f"Output path: {output_path}")
            ydl_opts = {
                **self.DEFAULT_OPTS,
                "format": selected_format,
                "outtmpl": output_path,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                logger.debug(f"    → yt-dlp.YoutubeDL starting download for {video_id}...")
                info = ydl.extract_info(video_id, download=True)
                # yt-dlp may add extension or change filename, get actual path from info
                actual_path = ydl.prepare_filename(info)
                logger.debug(f"      ✓ yt-dlp extract_info complete")
                logger.debug(f"      → Actual file path: {actual_path}")
                return actual_path, None

        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            logger.error(f"    ✗ yt-dlp download error: {error_msg}")
            return None, self._parse_error_message(error_msg)

        except Exception as e:
            logger.exception(f"    ✗ yt-dlp unexpected error: {str(e)}")
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
