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
        self.progress_callback: Optional[callable] = None
    
    def set_progress_callback(self, callback: callable) -> None:
        """
        Set callback for download progress events.
        
        Callback will be called with yt-dlp's progress_hooks format:
        {
            'status': 'downloading',
            'downloaded_bytes': 1024000,
            'total_bytes': 10240000,
            '_speed_str': '1.23MiB/s',
            'filename': 'video.mp4'
        }
        
        Args:
            callback: Async function that receives progress dict
        """
        self.progress_callback = callback

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
            
            # Add progress hook if callback is configured
            if self.progress_callback:
                ydl_opts["progress_hooks"] = [self._create_progress_hook(video_id)]

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

    def _create_progress_hook(self, video_id: str):
        """
        Create a progress hook for yt-dlp that calls the async callback.
        
        yt-dlp progress_hooks are synchronous, but we need to call async callbacks.
        We use asyncio.run in a thread-safe way to bridge the gap.
        
        Args:
            video_id: Video ID for context
            
        Returns:
            Synchronous progress hook function
        """
        import asyncio
        import threading
        
        def progress_hook(d):
            if not self.progress_callback:
                return
            
            # Map yt-dlp progress status to our format
            status = d.get('status', 'unknown')
            
            # Skip post-processing and finished statuses for cleaner output
            if status in ('finished', 'error'):
                return
            
            # Extract progress info
            downloaded = d.get('downloaded_bytes', 0)
            total = d.get('total_bytes', 0) or d.get('total_bytes_estimate', 0)
            
            # Calculate progress percentage
            progress_percent = 0
            if total > 0:
                progress_percent = int((downloaded / total) * 100)
            
            # Map yt-dlp status to our status names
            status_map = {
                'downloading': 'DOWNLOADING',
                'processing': 'PROCESSING',
            }
            current_status = status_map.get(status, status.upper())
            
            # Determine current step from yt-dlp info
            current_step = d.get('_speed_str', 'Downloading...')
            if status == 'processing':
                current_step = 'Post-processing (merging audio/video)'
            
            progress_data = {
                "video_id": video_id,
                "status": current_status,
                "progress_percent": progress_percent,
                "current_step": current_step,
                "downloaded_bytes": downloaded,
                "total_bytes": total,
            }
            
            # Call the async callback in a way that works with sync progress hooks
            try:
                # Try to get the current event loop
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    # If loop is already running, schedule as task
                    asyncio.create_task(self.progress_callback(progress_data))
                else:
                    # Otherwise run it directly
                    loop.run_until_complete(self.progress_callback(progress_data))
            except RuntimeError:
                # No event loop, create one in this thread
                new_loop = asyncio.new_event_loop()
                asyncio.set_event_loop(new_loop)
                new_loop.run_until_complete(self.progress_callback(progress_data))
        
        return progress_hook

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
