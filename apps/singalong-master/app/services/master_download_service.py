"""Master download service for managing video downloads from YouTube"""

import os
import logging
import asyncio
from pathlib import Path
from typing import Optional, Tuple
import yt_dlp

logger = logging.getLogger(__name__)


class MasterDownloadService:
    """Service for downloading videos via YT-DLP"""

    def __init__(self, output_dir: str = "/data/master/videos"):
        """
        Initialize download service.

        Args:
            output_dir: Directory to store downloaded videos
        """
        self.output_dir = output_dir
        self._ensure_output_dir()

    def _ensure_output_dir(self):
        """Create output directory if it doesn't exist"""
        Path(self.output_dir).mkdir(parents=True, exist_ok=True)

    async def download_video_async(
        self,
        video_id: str,
        filename: str,
        timeout: int = 300,
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Download video from YouTube asynchronously.

        Args:
            video_id: YouTube video ID
            filename: Target filename (without path)
            timeout: Maximum download time in seconds

        Returns:
            Tuple of (file_path, error_message)
            - If successful: (full_path_to_file, None)
            - If failed: (None, error_message)
        """
        try:
            logger.info(f"▶ [ASYNC DOWNLOAD START] Video ID: {video_id} | Filename: {filename} | Timeout: {timeout}s")

            output_path = os.path.join(self.output_dir, filename)
            logger.debug(f"  → Output path: {output_path}")

            # Use yt-dlp Python library with async execution
            logger.debug(f"  → Preparing yt-dlp options...")
            ydl_opts = {
                "format": "bestvideo+bestaudio/best",
                "socket_timeout": 30,
                "quiet": True,
                "no_warnings": True,
                "outtmpl": output_path,  # Output path for the file
            }

            # Run download in thread pool to avoid blocking
            logger.debug(f"  → Starting yt-dlp in thread pool executor...")
            loop = asyncio.get_event_loop()
            output_path_result, error_msg = await asyncio.wait_for(
                loop.run_in_executor(
                    None,
                    self._download_with_ydl,
                    video_id,
                    output_path,
                    ydl_opts,
                ),
                timeout=timeout,
            )

            if error_msg:
                logger.error(f"  ✗ Download error: {error_msg}")
                return None, error_msg

            if not os.path.exists(output_path_result):
                error_msg = f"File not created at {output_path_result}"
                logger.error(f"  ✗ {error_msg}")
                return None, error_msg

            file_size = os.path.getsize(output_path_result)
            logger.info(f"  ✓ Download complete: {output_path_result}")
            logger.info(f"    File size: {file_size} bytes ({file_size / 1024 / 1024:.2f} MB)")
            logger.info(f"◀ [ASYNC DOWNLOAD END] Success")

            return output_path_result, None

        except asyncio.TimeoutError:
            error_msg = f"Download timeout after {timeout} seconds"
            logger.error(f"  ✗ [ASYNC DOWNLOAD TIMEOUT] {error_msg}")
            logger.info(f"◀ [ASYNC DOWNLOAD END] Failed")
            return None, error_msg
        except Exception as e:
            error_msg = f"Unexpected download error: {str(e)}"
            logger.exception(f"  ✗ [ASYNC DOWNLOAD EXCEPTION] {error_msg}")
            logger.info(f"◀ [ASYNC DOWNLOAD END] Failed")
            return None, error_msg

    @staticmethod
    def _download_with_ydl(
        video_id: str, output_path: str, ydl_opts: dict
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Helper method to run yt-dlp download in thread pool.

        Returns:
            Tuple of (actual_file_path, error_message)
        """
        try:
            logger.debug(f"    → yt-dlp.YoutubeDL starting download...")
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                logger.debug(f"      → extract_info('{video_id}', download=True)...")
                info = ydl.extract_info(video_id, download=True)
                # yt-dlp may add extension or change filename, get actual path from info
                actual_path = ydl.prepare_filename(info)
                logger.debug(f"      ✓ yt-dlp extract_info complete")
                logger.debug(f"      → Actual file path: {actual_path}")
                return actual_path, None

        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            logger.error(f"    ✗ yt-dlp download error: {error_msg}")

            if "not available" in error_msg.lower():
                return None, "Video not found or removed"
            elif "age-restricted" in error_msg.lower():
                return None, "Video is age-restricted"
            elif "private" in error_msg.lower():
                return None, "Video is private"

            return None, error_msg
        except Exception as e:
            logger.exception(f"    ✗ yt-dlp unexpected error: {str(e)}")
            return None, f"Unexpected error: {str(e)}"

    def download_video_sync(
        self,
        video_id: str,
        filename: str,
        timeout: int = 300,
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Download video from YouTube synchronously (blocking).

        Args:
            video_id: YouTube video ID
            filename: Target filename (without path)
            timeout: Maximum download time in seconds

        Returns:
            Tuple of (file_path, error_message)
        """
        try:
            logger.info(f"▶ [SYNC DOWNLOAD START] Video ID: {video_id} | Filename: {filename}")

            output_path = os.path.join(self.output_dir, filename)
            logger.debug(f"  → Output path: {output_path}")

            logger.debug(f"  → Preparing yt-dlp options...")
            ydl_opts = {
                "format": "bestvideo+bestaudio/best",
                "socket_timeout": 30,
                "quiet": True,
                "no_warnings": True,
                "outtmpl": output_path,
            }

            logger.debug(f"  → Calling yt-dlp library (sync)...")
            actual_path, error_msg = self._download_with_ydl(video_id, output_path, ydl_opts)

            if error_msg:
                logger.error(f"  ✗ Download error: {error_msg}")
                logger.info(f"◀ [SYNC DOWNLOAD END] Failed")
                return None, error_msg

            if not os.path.exists(actual_path):
                error_msg = f"File not created at {actual_path}"
                logger.error(f"  ✗ {error_msg}")
                logger.info(f"◀ [SYNC DOWNLOAD END] Failed")
                return None, error_msg

            file_size = os.path.getsize(actual_path)
            logger.info(f"  ✓ Download complete: {actual_path}")
            logger.info(f"    File size: {file_size} bytes ({file_size / 1024 / 1024:.2f} MB)")
            logger.info(f"◀ [SYNC DOWNLOAD END] Success")

            return actual_path, None

        except Exception as e:
            error_msg = f"Unexpected download error: {str(e)}"
            logger.exception(f"  ✗ [SYNC DOWNLOAD EXCEPTION] {error_msg}")
            logger.info(f"◀ [SYNC DOWNLOAD END] Failed")
            return None, error_msg
            return None, error_msg

    def get_file_size(self, file_path: str) -> Optional[int]:
        """Get file size in bytes"""
        try:
            if os.path.exists(file_path):
                return os.path.getsize(file_path)
        except Exception as e:
            logger.error(f"Error getting file size: {str(e)}")
        return None

    def file_exists(self, file_path: str) -> bool:
        """Check if file exists"""
        return os.path.exists(file_path)
