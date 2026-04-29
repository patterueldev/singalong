"""Master download service for managing video downloads from YouTube"""

import os
import subprocess
import logging
import asyncio
from pathlib import Path
from typing import Optional, Tuple

logger = logging.getLogger(__name__)


class MasterDownloadService:
    """Service for downloading videos via YT-DLP"""

    def __init__(self, output_dir: str = "./data/master/videos"):
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
            logger.info(f"Starting async download: {video_id} → {filename}")

            # Build yt-dlp command
            output_path = os.path.join(self.output_dir, filename)
            output_template = os.path.splitext(output_path)[0]  # Remove .mp4

            cmd = [
                "yt-dlp",
                "--format",
                "best",  # Best quality available
                "--socket-timeout",
                "30",
                "--quiet",  # Less verbose
                "--no-warnings",
                "-o",
                output_template,  # Output template without extension
                f"https://www.youtube.com/watch?v={video_id}",
            ]

            logger.debug(f"Running yt-dlp: {' '.join(cmd)}")

            # Run download in background
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )

            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout,
                )
            except asyncio.TimeoutError:
                process.kill()
                error_msg = f"Download timeout after {timeout} seconds"
                logger.error(error_msg)
                return None, error_msg

            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "Unknown error"
                logger.error(f"yt-dlp error: {error_msg}")

                # Provide better error messages
                if "not available" in error_msg.lower():
                    error_msg = "Video not found or removed"
                elif "age-restricted" in error_msg.lower():
                    error_msg = "Video is age-restricted"
                elif "private" in error_msg.lower():
                    error_msg = "Video is private"

                return None, error_msg

            # Verify file exists
            if not os.path.exists(output_path):
                error_msg = f"File not created at {output_path}"
                logger.error(error_msg)
                return None, error_msg

            file_size = os.path.getsize(output_path)
            logger.info(f"✓ Download complete: {output_path} ({file_size} bytes)")

            return output_path, None

        except Exception as e:
            error_msg = f"Unexpected download error: {str(e)}"
            logger.exception(error_msg)
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
            timeout: Maximum download time in seconds

        Returns:
            Tuple of (file_path, error_message)
        """
        try:
            logger.info(f"Starting sync download: {video_id} → {filename}")

            output_path = os.path.join(self.output_dir, filename)
            output_template = os.path.splitext(output_path)[0]

            cmd = [
                "yt-dlp",
                "--format",
                "best",
                "--socket-timeout",
                "30",
                "--quiet",
                "--no-warnings",
                "-o",
                output_template,
                f"https://www.youtube.com/watch?v={video_id}",
            ]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )

            if result.returncode != 0:
                error_msg = result.stderr or "Unknown error"
                logger.error(f"yt-dlp error: {error_msg}")

                if "not available" in error_msg.lower():
                    error_msg = "Video not found or removed"
                elif "age-restricted" in error_msg.lower():
                    error_msg = "Video is age-restricted"
                elif "private" in error_msg.lower():
                    error_msg = "Video is private"

                return None, error_msg

            if not os.path.exists(output_path):
                error_msg = f"File not created at {output_path}"
                logger.error(error_msg)
                return None, error_msg

            file_size = os.path.getsize(output_path)
            logger.info(f"✓ Download complete: {output_path} ({file_size} bytes)")

            return output_path, None

        except subprocess.TimeoutExpired:
            error_msg = f"Download timeout after {timeout} seconds"
            logger.error(error_msg)
            return None, error_msg
        except Exception as e:
            error_msg = f"Unexpected download error: {str(e)}"
            logger.exception(error_msg)
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
