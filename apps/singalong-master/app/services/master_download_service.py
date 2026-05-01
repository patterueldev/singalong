"""Master download service for managing video downloads from YouTube

This service manages the download state, storage, and async/sync execution
of video downloads. The actual yt-dlp operations are delegated to YTDLPService.
"""

import os
import logging
import asyncio
from pathlib import Path
from typing import Optional, Tuple, Callable

from app.services.yt_dlp_service import YTDLPService

logger = logging.getLogger(__name__)


class MasterDownloadService:
    """Service for downloading and managing video files from YouTube"""

    def __init__(self, output_dir: str = "/data/master/videos"):
        """
        Initialize download service.

        Args:
            output_dir: Directory to store downloaded videos
        """
        self.output_dir = output_dir
        self.yt_dlp_service = YTDLPService()
        self.progress_callback: Optional[Callable] = None
        self.complete_callback: Optional[Callable] = None
        self._ensure_output_dir()
    
    def set_progress_callback(self, callback: Callable) -> None:
        """
        Set callback for download progress events.
        
        Callback signature: async def callback(video_id: str, progress: int, step: str)
        """
        self.progress_callback = callback
    
    def set_complete_callback(self, callback: Callable) -> None:
        """
        Set callback for download complete events.
        
        Callback signature: async def callback(video_id: str)
        """
        self.complete_callback = callback

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

            # Run download in thread pool to avoid blocking event loop
            logger.debug(f"  → Starting yt-dlp in thread pool executor...")
            loop = asyncio.get_event_loop()
            output_path_result, error_msg = await asyncio.wait_for(
                loop.run_in_executor(
                    None,
                    self.yt_dlp_service.download_video,
                    video_id,
                    output_path,
                ),
                timeout=timeout,
            )

            if error_msg:
                logger.error(f"  ✗ Download error: {error_msg}")
                logger.info(f"◀ [ASYNC DOWNLOAD END] Failed")
                return None, error_msg

            if not os.path.exists(output_path_result):
                error_msg = f"File not created at {output_path_result}"
                logger.error(f"  ✗ {error_msg}")
                logger.info(f"◀ [ASYNC DOWNLOAD END] Failed")
                return None, error_msg

            file_size = os.path.getsize(output_path_result)
            logger.info(f"  ✓ Download complete: {output_path_result}")
            logger.info(f"    File size: {file_size} bytes ({file_size / 1024 / 1024:.2f} MB)")
            logger.info(f"◀ [ASYNC DOWNLOAD END] Success")

            # Notify completion via callback (WebSocket)
            if self.complete_callback:
                try:
                    await self.complete_callback(video_id)
                except Exception as e:
                    logger.error(f"Failed to call complete callback: {e}")

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
            timeout: Maximum download time in seconds (not used in sync version)

        Returns:
            Tuple of (file_path, error_message)
        """
        try:
            logger.info(f"▶ [SYNC DOWNLOAD START] Video ID: {video_id} | Filename: {filename}")

            output_path = os.path.join(self.output_dir, filename)
            logger.debug(f"  → Output path: {output_path}")

            logger.debug(f"  → Calling yt-dlp library (sync)...")
            actual_path, error_msg = self.yt_dlp_service.download_video(video_id, output_path)

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

            # Notify completion via callback (WebSocket) - sync version uses asyncio.run
            if self.complete_callback:
                try:
                    asyncio.run(self.complete_callback(video_id))
                except Exception as e:
                    logger.error(f"Failed to call complete callback: {e}")

            return actual_path, None

        except Exception as e:
            error_msg = f"Unexpected download error: {str(e)}"
            logger.exception(f"  ✗ [SYNC DOWNLOAD EXCEPTION] {error_msg}")
            logger.info(f"◀ [SYNC DOWNLOAD END] Failed")
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
