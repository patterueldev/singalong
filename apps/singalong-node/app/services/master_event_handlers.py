"""
WebSocket Event Handlers for Master broadcasts

Handles download progress, completion, and other real-time events
from Master WebSocket endpoint.
"""

import logging
import asyncio
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

        When a download completes on Master, automatically trigger a sync
        on Node to pull the newly downloaded video into local cache.

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

            # Trigger catalog sync to download video file to local storage
            # This runs in background so we don't block the event handler
            try:
                await MasterEventHandlers._trigger_sync_for_video(video_id)
            except Exception as sync_error:
                logger.error(
                    f"Failed to trigger sync after download: {sync_error}",
                    exc_info=True
                )

        except Exception as e:
            logger.error(f"Error handling download complete: {e}")

    @staticmethod
    async def _trigger_sync_for_video(video_id: str) -> None:
        """
        Trigger catalog sync on Node to download newly completed video.

        Calls Node's sync endpoint to fetch the video file from Master.
        Runs asynchronously in background.

        Args:
            video_id: YouTube video ID that was just downloaded
        """
        try:
            import httpx
            from app.config import settings
            from app.services.master_auth_manager import get_access_token

            # Get Node's own JWT token for the sync endpoint
            access_token = get_access_token()
            if not access_token:
                logger.error("Cannot trigger sync: No access token available")
                return

            # Call local Node sync endpoint
            # Note: In docker-compose, use service name 'node' for inter-container calls
            sync_url = "http://node:5002/api/songs/sync"
            headers = {"Authorization": f"Bearer {access_token}"}

            logger.info(f"[AUTO-SYNC] Triggering sync for newly downloaded video: {video_id}")

            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(sync_url, headers=headers)
                response.raise_for_status()

                result = response.json()
                logger.info(
                    f"[AUTO-SYNC] Sync triggered successfully: task_id={result.get('task_id')}"
                )

        except httpx.HTTPError as http_error:
            logger.error(f"HTTP error triggering sync: {http_error}")
        except Exception as e:
            logger.error(f"Unexpected error triggering sync: {e}", exc_info=True)

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
