"""
Service for syncing songs from Master to Node's local database.

Handles pulling ACTIVE songs from Master via GraphQL, downloading video files,
and updating Node's local Song table.
"""

import asyncio
import logging
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Optional
from uuid import UUID

import httpx
from sqlalchemy.orm import Session as SQLSession

from app.models.db_models import Song
from app.utils.file_naming import generate_filename
from app.services.graphql_client import MasterGraphQLClient, GraphQLError

logger = logging.getLogger(__name__)


class SyncResult:
    """Result of a sync operation"""
    def __init__(self):
        self.synced = 0  # New songs synced
        self.updated = 0  # Existing songs updated
        self.failed = 0  # Failed to sync
        self.errors: List[str] = []
    
    def to_dict(self) -> dict:
        return {
            "synced": self.synced,
            "updated": self.updated,
            "failed": self.failed,
            "errors": self.errors,
            "total_processed": self.synced + self.updated + self.failed,
        }


class NodeSyncService:
    """Service for syncing songs from Master to Node"""
    
    # Node's local video storage directory (absolute path for Docker volumes)
    VIDEOS_DIR = Path("/data/node/videos")
    
    def __init__(self, db: SQLSession):
        self.db = db
        from app.config import settings
        self.master_client = MasterGraphQLClient(settings.master_graphql_url)
        # Ensure videos directory exists
        self.VIDEOS_DIR.mkdir(parents=True, exist_ok=True)
    
    async def sync_songs_from_master(self, limit: int = 100, offset: int = 0) -> SyncResult:
        """
        Sync ACTIVE songs from Master to Node's local database.
        
        Process:
        1. Query Master for ACTIVE songs (paginated)
        2. For each song:
           - Check if already in local database
           - Download video file from Master to /data/node/videos/
           - Create/update Song record with local file path
        3. Skip songs that fail to download
        
        Args:
            limit: How many songs to sync per batch (default 100)
            offset: Starting position for pagination
        
        Returns:
            SyncResult with counts and errors
        """
        result = SyncResult()
        
        try:
            logger.info(f"Starting sync from Master (limit={limit}, offset={offset})")
            
            # Query Master for active songs
            master_songs = await self._query_master_songs(limit, offset)
            if not master_songs:
                logger.info("No songs to sync from Master")
                return result
            
            logger.info(f"Master returned {len(master_songs)} songs to sync")
            
            # Process each song
            for master_song in master_songs:
                try:
                    # Check if song already exists locally (by id or video_id)
                    song_id = UUID(master_song["id"]) if isinstance(master_song["id"], str) else master_song["id"]
                    video_id = master_song.get("videoId")
                    
                    # Check both by id and by video_id to avoid UNIQUE constraint errors
                    existing = self.db.query(Song).filter(
                        (Song.id == song_id) | (Song.video_id == video_id)
                    ).first()
                    
                    # Download video file from Master
                    local_file_path = await self._download_video_from_master(master_song)
                    if not local_file_path:
                        error_msg = f"Failed to download video for {master_song.get('title', 'unknown')}"
                        logger.error(error_msg)
                        result.failed += 1
                        result.errors.append(error_msg)
                        continue
                    
                    if existing:
                        # Update existing song
                        logger.debug(f"Updating song: {master_song['title']}")
                        self._update_song(existing, master_song, local_file_path)
                        result.updated += 1
                    else:
                        # Create new song record
                        logger.info(f"Syncing new song: {master_song['title']} from {local_file_path}")
                        self._create_song(master_song, local_file_path)
                        result.synced += 1
                        
                except Exception as e:
                    error_msg = f"Failed to sync {master_song.get('title', 'unknown')}: {str(e)}"
                    logger.error(error_msg, exc_info=True)
                    result.failed += 1
                    result.errors.append(error_msg)
            
            self.db.commit()
            logger.info(f"Sync complete: {result.synced} new, {result.updated} updated, {result.failed} failed")
            
        except GraphQLError as e:
            error_msg = f"Master query error: {str(e)}"
            logger.error(error_msg)
            result.failed += 1
            result.errors.append(error_msg)
        except Exception as e:
            error_msg = f"Unexpected sync error: {str(e)}"
            logger.error(error_msg, exc_info=True)
            result.failed += 1
            result.errors.append(error_msg)
        
        return result
    
    async def _query_master_songs(self, limit: int = 100, offset: int = 0) -> List[dict]:
        """
        Query Master for ACTIVE songs.
        
        Returns:
            List of song dictionaries from Master
        """
        query = """
            query ActiveSongs($limit: Int, $offset: Int) {
                activeSongs(limit: $limit, offset: $offset) {
                    songs {
                        id
                        title
                        artist
                        duration
                        year
                        source
                        videoId
                        thumbnail
                        filePath
                        status
                    }
                    total
                }
            }
        """
        
        variables = {
            "limit": limit,
            "offset": offset,
        }
        
        try:
            response = await self.master_client.execute_query(query, variables)
            songs = response.get("activeSongs", {}).get("songs", [])
            logger.debug(f"Master returned {len(songs)} songs")
            return songs
        except Exception as e:
            logger.error(f"Failed to query Master: {str(e)}")
            raise GraphQLError(f"Failed to query Master: {str(e)}")
    
    def _create_song(self, master_song: dict, local_file_path: str):
        """
        Create a new local Song record from Master song data.
        
        Args:
            master_song: Song data from Master
            local_file_path: Path to downloaded video file on Node
        """
        song = Song(
            id=UUID(master_song["id"]),
            title=master_song.get("title"),
            artist=master_song.get("artist"),
            duration=master_song.get("duration"),
            year=master_song.get("year"),
            source=master_song.get("source", "youtube"),
            video_id=master_song.get("videoId"),
            thumbnail=master_song.get("thumbnail"),
            status="ACTIVE",
            file_path=local_file_path,  # Local Node copy
            synced_at=datetime.now(timezone.utc),
        )
        self.db.add(song)
        logger.debug(f"Created local Song record: {song.title} -> {local_file_path}")
    
    def _update_song(self, song: Song, master_song: dict, local_file_path: str = None):
        """
        Update an existing local Song record with Master data.
        
        Args:
            song: Existing Song record
            master_song: Updated data from Master
            local_file_path: Path to downloaded video file (if re-syncing)
        """
        song.title = master_song.get("title", song.title)
        song.artist = master_song.get("artist", song.artist)
        song.duration = master_song.get("duration", song.duration)
        song.year = master_song.get("year", song.year)
        song.thumbnail = master_song.get("thumbnail", song.thumbnail)
        if local_file_path:
            song.file_path = local_file_path
        song.status = "ACTIVE"
        song.synced_at = datetime.now(timezone.utc)
        logger.debug(f"Updated Song record: {song.title}")
    
    async def _download_video_from_master(self, master_song: dict) -> Optional[str]:
        """
        Download video file from Master to Node's local storage.
        
        The video is served by Master's /api/songs/video/{videoId} endpoint.
        Downloads to /data/node/videos/{filename}
        
        Args:
            master_song: Song data from Master containing videoId
        
        Returns:
            Path to downloaded file, or None if failed
        """
        try:
            video_id = master_song.get("videoId")
            if not video_id:
                logger.error(f"No videoId for song {master_song.get('title')}")
                return None
            
            from app.config import settings
            
            # Construct download URL from Master
            master_base_url = settings.master_url.rstrip('/')
            download_url = f"{master_base_url}/api/songs/video/{video_id}"
            
            # Create destination filename using normalized naming (alphanumeric_[videoId].mp4)
            title = master_song.get("title", "unknown")
            dest_filename = generate_filename(title, video_id)
            dest_path = self.VIDEOS_DIR / dest_filename
            
            logger.info(f"Downloading {master_song.get('title')} from {download_url} -> {dest_path}")
            
            # Download file from Master using httpx
            async with httpx.AsyncClient(timeout=300.0) as client:
                response = await client.get(download_url, follow_redirects=True)
                response.raise_for_status()
                
                # Write to local file
                with open(dest_path, 'wb') as f:
                    f.write(response.content)
            
            file_size = os.path.getsize(dest_path)
            logger.info(f"Downloaded {dest_filename} ({file_size} bytes)")
            
            # Return absolute path for database storage
            return str(dest_path.absolute())
            
        except Exception as e:
            logger.error(f"Failed to download video {master_song.get('videoId', 'unknown')}: {str(e)}", exc_info=True)
            return None
    
    def get_synced_songs(
        self,
        search: Optional[str] = None,
        status: str = "ACTIVE",
        limit: int = 10,
        offset: int = 0,
    ) -> tuple[List[Song], int]:
        """
        Query local database for synced songs.
        
        Args:
            search: Optional keyword to filter by title/artist
            status: Filter by status (default: ACTIVE)
            limit: Results per page
            offset: Pagination offset
        
        Returns:
            Tuple of (songs, total_count)
        """
        query = self.db.query(Song).filter(Song.status == status)
        
        # Apply search filter if provided
        if search:
            search_term = f"%{search}%"
            from sqlalchemy import or_
            query = query.filter(
                or_(
                    Song.title.ilike(search_term),
                    Song.artist.ilike(search_term),
                )
            )
        
        # Get total count before pagination
        total = query.count()
        
        # Apply sorting and pagination
        songs = query.order_by(Song.title).limit(limit).offset(offset).all()
        
        return songs, total
    
    def mark_song_corrupted(self, song_id: str):
        """
        Mark a song as CORRUPTED if its file is missing.
        
        Args:
            song_id: Song UUID to mark
        """
        song = self.db.query(Song).filter(Song.id == song_id).first()
        if not song:
            logger.warning(f"Song not found: {song_id}")
            return
        
        # Check if file exists
        if not song.file_path or not Path(song.file_path).exists():
            song.status = "CORRUPTED"
            self.db.commit()
            logger.warning(f"Marked song as CORRUPTED: {song.title} (file missing)")
        else:
            logger.debug(f"Song file exists: {song.file_path}")
    
    def sync_download_song_file(self, song_id: str, source_file_path: str) -> Optional[str]:
        """
        Download/copy a song file from Master to Node's local storage.
        
        For MVP, uses mounted volume (both services access ./data/)
        
        Args:
            song_id: Song UUID
            source_file_path: Master's file path (e.g., ./data/master/videos/filename.mp4)
        
        Returns:
            Local file path if successful, None if failed
        """
        song = self.db.query(Song).filter(Song.id == song_id).first()
        if not song:
            logger.error(f"Song not found: {song_id}")
            return None
        
        try:
            source_path = Path(source_file_path)
            if not source_path.exists():
                logger.error(f"Source file not found: {source_file_path}")
                return None
            
            # Use same filename for local storage
            filename = source_path.name
            dest_path = self.VIDEOS_DIR / filename
            
            logger.info(f"Downloading {song.title}: {source_path} → {dest_path}")
            
            # Copy file (using mount) or symlink
            if source_path.samefile(dest_path) if dest_path.exists() else False:
                logger.debug(f"File already at destination: {dest_path}")
            else:
                shutil.copy2(source_path, dest_path)
                logger.info(f"Downloaded: {dest_path}")
            
            # Update song record with local path
            song.file_path = str(dest_path)
            self.db.commit()
            
            return str(dest_path)
            
        except Exception as e:
            logger.error(f"Failed to download song file: {str(e)}", exc_info=True)
            return None
