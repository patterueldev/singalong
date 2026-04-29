"""
Download service for managing song downloads from YouTube

Handles async downloads with progress tracking and error handling.
"""

import os
import logging
import subprocess
import threading
from pathlib import Path
from typing import Optional, Callable
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.db_models import DraftSong, Song, utc_now
from app.services.yt_dlp_service import YTDLPService, YTDLPError

logger = logging.getLogger(__name__)


def utc_now_tz():
    """Get current UTC datetime with timezone"""
    return datetime.now(timezone.utc)


class DownloadService:
    """Service for handling song downloads with async processing"""

    def __init__(self, db: Session, output_dir: str = "/songs"):
        """
        Initialize download service

        Args:
            db: SQLAlchemy database session
            output_dir: Directory to store downloaded files
        """
        self.db = db
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"DownloadService initialized with output_dir: {self.output_dir}")

    def request_download(
        self,
        url: str,
        title: str,
        artist: Optional[str] = None,
        duration: Optional[int] = None,
        language: Optional[str] = None,
        enhanced_metadata: Optional[dict] = None,
        requested_by_node_id: str = "unknown",
    ) -> DraftSong:
        """
        Request a song download (async in background)

        Creates a draft record and starts async download in background thread.

        Args:
            url: YouTube URL
            title: Song title
            artist: Artist name
            duration: Song duration in seconds
            language: Song language
            enhanced_metadata: User-edited metadata
            requested_by_node_id: Which node requested the download

        Returns:
            DraftSong record with status="pending"

        Raises:
            YTDLPError: If URL validation fails
        """
        # Validate URL
        yt_dlp = YTDLPService()
        if not yt_dlp.validate_url(url):
            raise YTDLPError("Invalid YouTube URL")

        # Create draft record
        draft = DraftSong(
            title=title,
            artist=artist,
            duration=str(duration) if duration else None,
            language=language,
            requested_by_node_id=requested_by_node_id,
            enhanced_metadata=str(enhanced_metadata) if enhanced_metadata else None,
            status="pending",
            download_progress="0",
        )
        self.db.add(draft)
        self.db.commit()
        self.db.refresh(draft)

        logger.info(f"Created draft {draft.id} for {title}")

        # Start async download in background thread
        thread = threading.Thread(
            target=self._download_async,
            args=(str(draft.id), url, draft.title),
            daemon=True,
        )
        thread.start()

        return draft

    def _download_async(self, draft_id: str, url: str, title: str):
        """
        Background task to download song

        Args:
            draft_id: Draft song UUID
            url: YouTube URL
            title: Song title (for logging)
        """
        try:
            # Fetch draft from DB (fresh session for thread)
            from app.database import SessionLocal

            db = SessionLocal()
            draft = db.query(DraftSong).filter(DraftSong.id == UUID(draft_id)).first()

            if not draft:
                logger.error(f"Draft {draft_id} not found")
                db.close()
                return

            # Update status to downloading
            draft.status = "downloading"
            draft.started_at = utc_now_tz()
            draft.download_progress = "0"
            db.commit()

            logger.info(f"Starting download for {title} ({draft_id})")

            # Download via yt-dlp
            output_path = self.output_dir / f"{draft_id}.mp4"

            result = subprocess.run(
                [
                    "yt-dlp",
                    "-f",
                    "best[ext=mp4]",
                    "-o",
                    str(output_path),
                    "--progress",
                    url,
                ],
                capture_output=True,
                text=True,
                timeout=3600,  # 1 hour timeout
            )

            if result.returncode != 0:
                # Download failed
                draft.status = "failed"
                draft.error_message = result.stderr[:500]  # Limit error message
                logger.error(f"Download failed for {draft_id}: {result.stderr}")
                db.commit()

            else:
                # Download succeeded
                if output_path.exists():
                    file_size = output_path.stat().st_size
                    draft.file_path = str(output_path)
                    draft.file_size = str(file_size)
                    draft.status = "finalized"
                    draft.download_progress = "100"
                    draft.completed_at = utc_now_tz()
                    draft.finalized_at = utc_now_tz()

                    # Create final song record
                    song = Song(
                        title=draft.title,
                        artist=draft.artist,
                        duration=draft.duration,
                        youtube_url=url,
                        file_path=str(output_path),
                        status="COMPLETED",
                        created_at=utc_now_tz(),
                        updated_at=utc_now_tz(),
                    )
                    db.add(song)

                    logger.info(f"Download completed for {draft_id}: {file_size} bytes")

                else:
                    draft.status = "failed"
                    draft.error_message = "Downloaded file not found"
                    logger.error(f"Downloaded file not found for {draft_id}")

                db.commit()

            # Call progress callbacks (future WebSocket integration)
            self._broadcast_progress(
                draft_id, draft.status, int(draft.download_progress)
            )

        except subprocess.TimeoutExpired:
            logger.error(f"Download timeout for {draft_id}")
            draft.status = "failed"
            draft.error_message = "Download timed out (>1 hour)"
            db.commit()

        except Exception as e:
            logger.exception(f"Error downloading {draft_id}: {str(e)}")
            try:
                draft.status = "failed"
                draft.error_message = str(e)[:500]
                db.commit()
            except Exception as db_error:
                logger.error(f"Failed to update draft {draft_id}: {db_error}")

        finally:
            db.close()

    def _broadcast_progress(self, draft_id: str, status: str, progress: int):
        """
        Placeholder for progress broadcasting (WebSocket/MQ integration)

        Args:
            draft_id: Draft song UUID
            status: Current download status
            progress: Progress percentage (0-100)
        """
        logger.info(f"Progress: {draft_id} {status} {progress}%")
        # [Future] Integrate WebSocket or message queue here
        # e.g., notify via channel layer, publish to MQ, etc.
