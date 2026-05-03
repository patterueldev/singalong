"""
WebSocket Event Handlers for Master broadcasts

Handles download progress, completion, and other real-time events
from Master WebSocket endpoint.
"""

import logging
import asyncio
import threading
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

        When a download completes on Master, automatically sync that video
        to Node's local cache by calling the sync service directly.

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

            # Directly call sync service in background (don't make HTTP call to ourselves!)
            logger.info(f"[AUTO-SYNC] Syncing newly downloaded video: {video_id}")
            
            # Run sync in background thread
            thread = threading.Thread(
                target=MasterEventHandlers._sync_video_in_background,
                args=(video_id,),
                daemon=True
            )
            thread.start()

        except Exception as e:
            logger.error(f"Error handling download complete: {e}")

    @staticmethod
    def _sync_video_in_background(video_id: str) -> None:
        """
        Sync a single video in background thread.
        
        This is called directly (not via HTTP) when Master broadcasts
        a download:complete event.
        
        Args:
            video_id: YouTube video ID that was just downloaded on Master
        """
        try:
            from app.services.node_sync_service import NodeSyncService
            from app.database import SessionLocal
            
            # Create database session for this thread
            db_session = SessionLocal()
            try:
                logger.info(f"[AUTO-SYNC] Starting sync for video: {video_id}")
                
                # Call sync service directly (no HTTP)
                sync_service = NodeSyncService(db_session)
                result = asyncio.run(sync_service.sync_songs_from_master(limit=100, offset=0))
                
                logger.info(
                    f"[AUTO-SYNC] Sync complete for {video_id}: "
                    f"synced={result.synced}, updated={result.updated}, "
                    f"failed={result.failed}"
                )
                if result.errors:
                    logger.warning(f"[AUTO-SYNC] Errors during sync: {result.errors}")
                    
            finally:
                db_session.close()
                
        except Exception as e:
            logger.error(f"[AUTO-SYNC] Error syncing video {video_id}: {e}", exc_info=True)

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
