"""Node-side download service for managing downloads from Master"""

import uuid
import logging
import json
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session as SQLSession

logger = logging.getLogger(__name__)


def utc_now():
    """Get current UTC datetime"""
    return datetime.now(timezone.utc)


class NodeDownloadService:
    """Service for managing song downloads on Node side"""

    def __init__(self, db: SQLSession):
        """
        Initialize node download service.

        Args:
            db: SQLAlchemy database session
        """
        self.db = db

    def create_download_queue_entry(
        self,
        video_id: str,
        title: str,
        master_download_id: str = None,
    ) -> dict:
        """
        Create a download queue entry to track Master download.

        Args:
            video_id: YouTube video ID
            title: Song title
            master_download_id: Draft song ID returned from Master GraphQL

        Returns:
            Dictionary with download queue info
        """
        try:
            entry_id = str(uuid.uuid4())

            # For now, just track in memory or simple storage
            # Later phases will add proper database table
            logger.info(
                f"Created download queue entry: {entry_id} "
                f"(video={video_id}, master_id={master_download_id})"
            )

            return {
                "download_id": entry_id,
                "video_id": video_id,
                "title": title,
                "master_download_id": master_download_id,
                "status": "pending",
                "created_at": utc_now().isoformat(),
            }

        except Exception as e:
            logger.error(f"Error creating download queue entry: {str(e)}")
            raise

    def get_active_downloads(self) -> list:
        """
        Get all active downloads being tracked.

        Returns:
            List of active download entries
        """
        # Placeholder: returns empty list for now
        # In B3, will query actual database table
        return []

    def update_download_status(
        self,
        download_id: str,
        status: str,
        progress: int = None,
        file_path: str = None,
        error_message: str = None,
    ) -> dict:
        """
        Update download status.

        Args:
            download_id: Download queue entry ID
            status: New status (pending/downloading/completed/failed)
            progress: Progress percentage
            file_path: Local file path if completed
            error_message: Error message if failed

        Returns:
            Updated download entry
        """
        logger.info(f"Updating download {download_id}: {status}")
        # Placeholder implementation
        return {
            "download_id": download_id,
            "status": status,
            "progress": progress,
        }
