"""Node-side download service for managing downloads from Master"""

import uuid
import logging
import json
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session as SQLSession

from app.models.db_models import DownloadQueue

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
            # Check if video is already in queue
            existing = self.db.query(DownloadQueue).filter(
                DownloadQueue.video_id == video_id
            ).first()
            
            if existing:
                logger.warning(f"Video {video_id} already in download queue")
                return {
                    "download_id": str(existing.id),
                    "video_id": existing.video_id,
                    "title": existing.title,
                    "master_download_id": existing.master_download_id,
                    "status": existing.status,
                    "created_at": existing.created_at.isoformat(),
                }
            
            # Create new queue entry
            entry = DownloadQueue(
                video_id=video_id,
                title=title,
                master_download_id=master_download_id,
                status="pending",
            )
            
            self.db.add(entry)
            self.db.commit()
            self.db.refresh(entry)
            
            logger.info(
                f"Created download queue entry: {entry.id} "
                f"(video={video_id}, master_id={master_download_id})"
            )

            return {
                "download_id": str(entry.id),
                "video_id": entry.video_id,
                "title": entry.title,
                "master_download_id": entry.master_download_id,
                "status": entry.status,
                "created_at": entry.created_at.isoformat(),
            }

        except Exception as e:
            self.db.rollback()
            logger.error(f"Error creating download queue entry: {str(e)}")
            raise

    def get_active_downloads(self) -> list:
        """
        Get all active downloads being tracked.

        Returns:
            List of active download entries
        """
        try:
            downloads = self.db.query(DownloadQueue).filter(
                DownloadQueue.status.in_(["pending", "downloading"])
            ).all()
            
            result = []
            for download in downloads:
                result.append({
                    "download_id": str(download.id),
                    "video_id": download.video_id,
                    "title": download.title,
                    "master_download_id": download.master_download_id,
                    "status": download.status,
                    "progress": download.progress,
                    "file_path": download.file_path,
                    "error_message": download.error_message,
                    "created_at": download.created_at.isoformat() if download.created_at else None,
                    "completed_at": download.completed_at.isoformat() if download.completed_at else None,
                })
            
            return result
            
        except Exception as e:
            logger.error(f"Error getting active downloads: {str(e)}")
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
        try:
            import uuid as uuid_module
            
            # Convert string UUID to UUID object if needed
            if isinstance(download_id, str):
                download_id = uuid_module.UUID(download_id)
            
            download = self.db.query(DownloadQueue).filter(
                DownloadQueue.id == download_id
            ).first()
            
            if not download:
                logger.error(f"Download queue entry not found: {download_id}")
                return {}
            
            download.status = status
            if progress is not None:
                download.progress = progress
            if file_path:
                download.file_path = file_path
            if error_message:
                download.error_message = error_message
            
            # Set completed_at when download finishes
            if status in ["completed", "failed"] and not download.completed_at:
                download.completed_at = utc_now()
            
            download.updated_at = utc_now()
            
            self.db.commit()
            self.db.refresh(download)
            
            logger.info(f"Updated download {download_id}: {status}")
            
            return {
                "download_id": str(download.id),
                "status": download.status,
                "progress": download.progress,
                "file_path": download.file_path,
                "error_message": download.error_message,
            }
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error updating download status: {str(e)}")
            raise
