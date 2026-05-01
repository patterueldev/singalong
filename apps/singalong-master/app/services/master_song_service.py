"""Master song service for managing songs in database"""

import uuid
import logging
import json
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session as SQLSession

from app.models.db_models import Song, DraftSong

logger = logging.getLogger(__name__)


def utc_now():
    """Get current UTC datetime"""
    return datetime.now(timezone.utc)


class MasterSongService:
    """Service for managing songs in Master database"""

    def __init__(self, db: SQLSession):
        """
        Initialize song service.

        Args:
            db: SQLAlchemy database session
        """
        self.db = db

    def check_video_exists(self, video_id: str) -> bool:
        """
        Check if video already exists in songs table.

        Args:
            video_id: YouTube video ID

        Returns:
            True if video exists, False otherwise
        """
        try:
            existing = self.db.query(DraftSong).filter(
                DraftSong.video_id == video_id
            ).first()
            if existing:
                logger.info(f"Video {video_id} already exists in draft_songs")
                return True

            # Also check completed songs
            existing_song = self.db.query(Song).filter(
                Song.youtube_url.contains(video_id)
            ).first()
            if existing_song:
                logger.info(f"Video {video_id} already exists in songs")
                return True

            return False
        except Exception as e:
            logger.error(f"Error checking video existence: {str(e)}")
            return False

    def create_draft_song(
        self,
        video_id: str,
        title: str,
        artist: str,
        year: str,
        language: str,
        duration: int,
        thumbnail: str,
        url: str,
        tags: list,
        lyrics: str,
        requested_by_node_id: str,
        enhanced_metadata: Optional[dict] = None,
    ) -> DraftSong:
        """
        Create a draft song record (before download).

        Args:
            video_id: YouTube video ID
            title: Song title
            artist: Song artist
            year: Release year
            language: ISO 639-1 language code
            duration: Duration in seconds
            thumbnail: Thumbnail URL
            url: YouTube URL
            tags: List of tags
            lyrics: Lyrics (empty string for now)
            requested_by_node_id: Node ID that requested download
            enhanced_metadata: Optional enhanced metadata JSON

        Returns:
            DraftSong object
        """
        try:
            draft_song = DraftSong(
                id=uuid.uuid4(),
                video_id=video_id,
                title=title,
                artist=artist,
                duration=str(duration),
                language=language,
                requested_by_node_id=requested_by_node_id,
                enhanced_metadata=json.dumps(enhanced_metadata) if enhanced_metadata else None,
                status="pending",  # Will be updated to "downloading" when download starts
                download_progress="0",
                error_message=None,
                file_path=None,
                file_size=None,
                created_at=utc_now(),
                started_at=None,
                completed_at=None,
                finalized_at=None,
            )

            self.db.add(draft_song)
            self.db.commit()
            self.db.refresh(draft_song)

            logger.info(f"Created draft song: {draft_song.id} ({title})")
            return draft_song

        except Exception as e:
            self.db.rollback()
            logger.error(f"Error creating draft song: {str(e)}")
            raise

    def update_draft_status(
        self,
        draft_song_id: str,
        status: str,
        progress: int = None,
        error_message: str = None,
        file_path: str = None,
        file_size: str = None,
    ) -> DraftSong:
        """
        Update draft song status.

        Args:
            draft_song_id: Draft song UUID (as string or UUID object)
            status: New status (pending, downloading, completed, failed)
            progress: Download progress (0-100)
            error_message: Error message if failed
            file_path: File path when completed
            file_size: File size when completed

        Returns:
            Updated DraftSong object
        """
        try:
            import uuid as uuid_module
            
            # Convert string UUID to UUID object if needed
            if isinstance(draft_song_id, str):
                draft_song_id = uuid_module.UUID(draft_song_id)
            
            draft_song = self.db.query(DraftSong).filter(
                DraftSong.id == draft_song_id
            ).first()

            if not draft_song:
                raise ValueError(f"Draft song not found: {draft_song_id}")

            draft_song.status = status
            if progress is not None:
                draft_song.download_progress = str(progress)
            if error_message:
                draft_song.error_message = error_message
            if file_path:
                draft_song.file_path = file_path
            if file_size:
                draft_song.file_size = file_size

            # Set started_at on first update
            if status == "downloading" and not draft_song.started_at:
                draft_song.started_at = utc_now()

            # Set completed_at on finish
            if status in ("completed", "failed") and not draft_song.completed_at:
                draft_song.completed_at = utc_now()

            self.db.commit()
            self.db.refresh(draft_song)

            logger.info(f"Updated draft song {draft_song_id}: {status}")
            return draft_song

        except Exception as e:
            self.db.rollback()
            logger.error(f"Error updating draft song: {str(e)}")
            raise

    def finalize_draft_to_song(self, draft_song_id: str) -> Song:
        """
        Convert a completed draft song into a final Song record.

        Args:
            draft_song_id: Draft song UUID to finalize (as string or UUID object)

        Returns:
            Finalized Song object
        """
        try:
            import uuid as uuid_module
            
            # Convert string UUID to UUID object if needed
            if isinstance(draft_song_id, str):
                draft_song_id = uuid_module.UUID(draft_song_id)
            
            draft_song = self.db.query(DraftSong).filter(
                DraftSong.id == draft_song_id
            ).first()

            if not draft_song:
                raise ValueError(f"Draft song not found: {draft_song_id}")

            if draft_song.status != "completed":
                raise ValueError(
                    f"Cannot finalize draft in status '{draft_song.status}'"
                )

            # Create final Song record
            song = Song(
                id=uuid.uuid4(),
                title=draft_song.title,
                artist=draft_song.artist,
                duration=draft_song.duration,
                genre=None,  # Not set yet
                year=draft_song.status if draft_song.status else None,
                youtube_url=f"https://www.youtube.com/watch?v={draft_song.video_id}",
                file_path=draft_song.file_path,
                status="ACTIVE",  # Now ready for use
                requested_by_admin_id=None,
                error_message=None,
                created_at=utc_now(),
                updated_at=utc_now(),
            )

            self.db.add(song)

            # Mark draft as finalized
            draft_song.status = "finalized"
            draft_song.finalized_at = utc_now()

            self.db.commit()
            self.db.refresh(song)

            logger.info(f"Finalized draft song to Song: {song.id}")
            return song

        except Exception as e:
            self.db.rollback()
            logger.error(f"Error finalizing draft song: {str(e)}")
            raise

    def get_draft_song(self, draft_song_id: str) -> Optional[DraftSong]:
        """Get draft song by ID"""
        try:
            import uuid as uuid_module
            
            # Convert string UUID to UUID object if needed
            if isinstance(draft_song_id, str):
                draft_song_id = uuid_module.UUID(draft_song_id)
            
            return self.db.query(DraftSong).filter(
                DraftSong.id == draft_song_id
            ).first()
        except Exception as e:
            logger.error(f"Error fetching draft song: {str(e)}")
            return None

    def get_active_songs(self, limit: int = 100) -> list:
        """Get all active songs (status='ACTIVE')"""
        try:
            return self.db.query(Song).filter(
                Song.status == "ACTIVE"
            ).limit(limit).all()
        except Exception as e:
            logger.error(f"Error fetching active songs: {str(e)}")
            return []
