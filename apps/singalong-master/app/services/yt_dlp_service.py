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

    def _create_format_selector(self):
        """
        Create a custom format selector function for yt-dlp.
        
        Selects the best video+audio combination based on:
        1. Prefers MP4 container
        2. Caps resolution at 1080p max
        3. Merges best video with compatible audio
        
        Returns:
            Callable format selector function
        """
        def format_selector(ctx):
            """
            Custom format selector that finds best video+audio combination.
            
            Handles both:
            1. Combined formats (video + audio in one)
            2. DASH formats (separate video and audio streams to merge)
            
            Formats are already sorted worst to best by yt-dlp.
            We reverse to search best-to-worst for our preferences.
            
            Args:
                ctx: yt-dlp format context with 'formats' list
                
            Yields:
                Format dict with format_id, ext, requested_formats, protocol
            """
            logger.info("  ✓ CUSTOM FORMAT SELECTOR INVOKED")
            
            formats = ctx.get('formats', [])
            if not formats:
                logger.error("  ✗ No formats available from yt-dlp")
                return
            
            # Reverse to search best-to-worst (yt-dlp sorts worst-to-best)
            formats_sorted = formats[::-1]
            
            # Log all formats for debugging
            logger.info(f"  → Found {len(formats)} total formats:")
            for fmt in formats:  # Log ALL formats to see what we have
                logger.info(
                    f"    {fmt.get('format_id')} | {fmt.get('ext')} | "
                    f"H:{fmt.get('height')} | V:{fmt.get('vcodec')} | A:{fmt.get('acodec')}"
                )
            
            # FIRST ATTEMPT: Look for combined formats (video + audio together)
            # Note: YouTube provides both progressive download (https) and HLS (m3u8) combined formats.
            # Progressive formats are lower resolution but work with simple HTTP downloads.
            # HLS formats are higher resolution but require streaming support.
            # We prefer progressive download combined formats for simplicity.
            logger.info("  → Searching for combined video+audio formats...")
            best_combined = None
            best_combined_height = 0
            
            for f in formats_sorted:
                # Skip if no video or audio codec
                if f.get('vcodec') == 'none' or f.get('acodec') == 'none':
                    continue
                
                # Skip storyboards
                if f.get('format_id', '').startswith('sb'):
                    continue
                
                height = f.get('height', 0)
                ext = f.get('ext', '')
                format_id = f.get('format_id', '')
                
                # Cap at 1080p, prefer highest resolution first, then prefer MP4
                if height > 0 and height <= 1080:
                    logger.debug(f"    Candidate combined: {format_id} {ext} {height}p")
                    # Update if:
                    # 1. First format found, OR
                    # 2. Higher resolution, OR  
                    # 3. Same resolution but prefer mp4
                    if best_combined is None:
                        best_combined = f
                        best_combined_height = height
                    elif height > best_combined_height:
                        # Higher resolution always wins
                        best_combined = f
                        best_combined_height = height
                    elif height == best_combined_height and ext == 'mp4' and best_combined.get('ext') != 'mp4':
                        # Same resolution, prefer MP4
                        best_combined = f
                        best_combined_height = height
            
            if best_combined:
                logger.info(f"    Selected combined: {best_combined['format_id']} {best_combined['ext']} ({best_combined_height}p)")
                # For combined formats, yield the full format dict as-is
                yield best_combined
                return
            
            # SECOND ATTEMPT: DASH formats (separate video and audio)
            logger.info("  → No combined formats found, searching for DASH (video+audio separate)...")
            
            best_video = None
            for f in formats_sorted:
                # Must have video, no audio (video-only)
                if f.get('vcodec') == 'none' or f.get('acodec') != 'none':
                    continue
                
                # Skip storyboards
                if f.get('format_id', '').startswith('sb'):
                    continue
                
                height = f.get('height', 0)
                ext = f.get('ext', '')
                format_id = f.get('format_id', '')
                
                # Cap at 1080p, prefer MP4
                if height <= 1080:
                    logger.debug(f"    Candidate video: {format_id} {ext} {height}p")
                    if best_video is None or (best_video.get('ext') != 'mp4' and ext == 'mp4'):
                        best_video = f
                        if ext == 'mp4':
                            break  # Found MP4, stop searching
            
            if not best_video:
                logger.error("  ✗ No suitable video format found (even for DASH)")
                return
            
            logger.info(f"    Selected video: {best_video['format_id']} {best_video['ext']}")
            
            # Find compatible audio
            audio_ext = {'mp4': 'm4a', 'webm': 'webm'}.get(best_video['ext'], 'm4a')
            best_audio = None
            
            for f in formats_sorted:
                # Must have audio, no video (audio-only)
                if f.get('acodec') == 'none' or f.get('vcodec') != 'none':
                    continue
                
                if f.get('ext') == audio_ext:
                    logger.debug(f"    Found audio: {f['format_id']} {f['ext']}")
                    best_audio = f
                    break
            
            if not best_audio:
                logger.error(f"  ✗ No compatible audio found for {audio_ext}")
                return
            
            logger.info(f"    Selected audio: {best_audio['format_id']} {best_audio['ext']}")
            
            # Merge video+audio
            merged_format_id = f"{best_video['format_id']}+{best_audio['format_id']}"
            logger.info(f"  ✓ Merged format: {merged_format_id}")
            
            yield {
                'format_id': merged_format_id,
                'ext': best_video['ext'],
                'requested_formats': [best_video, best_audio],
                'protocol': f"{best_video.get('protocol', 'https')}+{best_audio.get('protocol', 'https')}"
            }
        
        return format_selector

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

        Uses a custom format selector to intelligently choose video+audio combination.

        Args:
            video_id: YouTube video ID (not URL)
            output_path: Full file path where video should be saved

        Returns:
            Tuple of (actual_file_path, error_message)
            - If successful: (path_to_downloaded_file, None)
            - If failed: (None, error_message)
        """
        try:
            logger.debug(f"Starting download for video ID: {video_id}")
            logger.debug(f"Output path: {output_path}")
            
            # Create custom format selector
            format_selector = self._create_format_selector()
            
            ydl_opts = {
                **self.DEFAULT_OPTS,
                "format": format_selector,
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
