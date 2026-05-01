"""
WebSocket Event Handlers for Master broadcasts

Handles download progress, completion, and other real-time events
from Master WebSocket endpoint.
"""

import logging
from typing import Any

logger = logging.getLogger(__name__)


class MasterEventHandlers:
    """Handlers for events received from Master WebSocket"""

    @staticmethod
    async def handle_download_progress(data: dict[str, Any]) -> None:
        """
        Handle download progress event from Master.

        Event format:
        {
            "video_id": "abc123",
            "status": "downloading",
            "progress_percent": 35,
            "downloaded_bytes": 10485760,
            "total_bytes": 29360128,
            "speed_mbps": 2.5,
            "eta_seconds": 6240
        }
        """
        try:
            video_id = data.get("video_id", "unknown")
            progress = data.get("progress_percent", 0)
            status = data.get("status", "downloading")
            speed = data.get("speed_mbps", 0)
            eta = data.get("eta_seconds", 0)

            # Format ETA
            if eta > 0:
                minutes = eta // 60
                seconds = eta % 60
                eta_str = f"{minutes:02d}:{seconds:02d}"
            else:
                eta_str = "N/A"

            # Log progress in structured format
            logger.info(
                f"[DOWNLOAD PROGRESS] video_id={video_id} | {progress}% | "
                f"{speed:.2f}MB/s | ETA {eta_str}"
            )

        except Exception as e:
            logger.error(f"Error handling download progress: {e}")

    @staticmethod
    async def handle_download_complete(data: dict[str, Any]) -> None:
        """
        Handle download completion event from Master.

        Event format:
        {
            "video_id": "abc123",
            "title": "Song Title",
            "artist": "Artist Name"
        }
        """
        try:
            video_id = data.get("video_id", "unknown")
            title = data.get("title", "Unknown")
            artist = data.get("artist", "Unknown")

            logger.info(f"[DOWNLOAD COMPLETE] video_id={video_id} | {artist} - {title}")

            # TODO: Trigger catalog sync to download video file to local storage
            # await trigger_catalog_sync(video_id)

        except Exception as e:
            logger.error(f"Error handling download complete: {e}")

    @staticmethod
    async def handle_catalog_updated(data: dict[str, Any]) -> None:
        """Handle catalog update event from Master"""
        try:
            logger.info(f"[CATALOG UPDATED] Master has new videos")
            # TODO: Trigger sync to fetch updated catalog
        except Exception as e:
            logger.error(f"Error handling catalog update: {e}")

    @staticmethod
    async def handle_system_health(data: dict[str, Any]) -> None:
        """Handle system health heartbeat from Master"""
        try:
            status = data.get("status", "unknown")
            logger.debug(f"[SYSTEM HEALTH] Master: {status}")
        except Exception as e:
            logger.error(f"Error handling system health: {e}")
