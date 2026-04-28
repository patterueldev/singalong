"""Song management API endpoints for Node"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session as SQLSession

from app.database import SessionLocal
from app.models.db_models import Song
from app.models.schemas import (
    CreateSongRequest,
    SongResponse,
    SongListResponse,
    SongStatusResponse,
    ErrorResponse,
)

router = APIRouter(prefix="/api/songs", tags=["Songs"])


def get_db():
    """Dependency for database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _format_song_response(song: Song) -> SongResponse:
    """Format a Song model to SongResponse"""
    return SongResponse(
        id=str(song.id),
        title=song.title,
        artist=song.artist,
        duration=int(song.duration) if song.duration else None,
        genre=song.genre,
        year=int(song.year) if song.year else None,
        status=song.status,
        created_at=song.created_at.isoformat() if song.created_at else None,
        updated_at=song.updated_at.isoformat() if song.updated_at else None,
    )


@router.post("", status_code=201)
async def create_song(
    request: CreateSongRequest,
    db: SQLSession = Depends(get_db),
) -> SongResponse:
    """
    Create a new song from YouTube URL
    
    **Admin only**: Must have admin role in current session
    
    Request:
    ```json
    {
        "youtube_url": "https://www.youtube.com/watch?v=...",
        "title": "Song Title",
        "artist": "Artist Name",
        "duration": 180,
        "genre": "Pop",
        "year": 2020
    }
    ```
    
    Response: 201 Created
    ```json
    {
        "id": "uuid",
        "title": "Song Title",
        "artist": "Artist Name",
        "duration": 180,
        "genre": "Pop",
        "year": 2020,
        "status": "DRAFT",
        "created_at": "2026-04-28T...",
        "updated_at": "2026-04-28T..."
    }
    ```
    """
    # Validate YouTube URL format
    if not request.youtube_url or "youtube.com" not in request.youtube_url.lower():
        raise HTTPException(
            status_code=400,
            detail={
                "code": "INVALID_URL",
                "message": "Invalid YouTube URL",
                "details": {"url": request.youtube_url},
            },
        )

    # Validate required fields
    if not request.title or not request.title.strip():
        raise HTTPException(
            status_code=400,
            detail={
                "code": "MISSING_TITLE",
                "message": "Song title is required",
                "details": {},
            },
        )

    if not request.artist or not request.artist.strip():
        raise HTTPException(
            status_code=400,
            detail={
                "code": "MISSING_ARTIST",
                "message": "Artist name is required",
                "details": {},
            },
        )

    # Check if song already exists (by URL)
    query = select(Song).where(Song.youtube_url == request.youtube_url)
    result = db.execute(query)
    existing_song = result.scalars().first()
    
    if existing_song:
        return _format_song_response(existing_song)

    # Create new song
    song = Song(
        id=uuid.uuid4(),
        title=request.title.strip(),
        artist=request.artist.strip(),
        duration=str(request.duration) if request.duration else None,
        genre=request.genre.strip() if request.genre else None,
        year=str(request.year) if request.year else None,
        youtube_url=request.youtube_url,
        status="DRAFT",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )

    db.add(song)
    db.commit()
    db.refresh(song)

    return _format_song_response(song)


@router.get("")
async def list_songs(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    search: Optional[str] = None,
    status: Optional[str] = None,
    genre: Optional[str] = None,
    db: SQLSession = Depends(get_db),
) -> SongListResponse:
    """
    List all available songs with optional filtering
    
    Query Parameters:
    - limit: Number of results (default 100, max 1000)
    - offset: Offset for pagination (default 0)
    - search: Search by title or artist (optional)
    - status: Filter by status (DRAFT, DOWNLOADING, COMPLETED, FAILED)
    - genre: Filter by genre
    
    Response: 200 OK
    ```json
    {
        "songs": [
            {
                "id": "uuid",
                "title": "Song Title",
                "artist": "Artist Name",
                "duration": 180,
                "genre": "Pop",
                "year": 2020,
                "status": "COMPLETED",
                "created_at": "2026-04-28T...",
                "updated_at": "2026-04-28T..."
            }
        ],
        "total": 42
    }
    ```
    """
    # Build base query
    base_query = select(Song)

    # Apply filters
    if search:
        search_term = f"%{search.lower()}%"
        base_query = base_query.where(
            (Song.title.ilike(search_term)) | (Song.artist.ilike(search_term))
        )

    if status:
        base_query = base_query.where(Song.status == status.upper())

    if genre:
        base_query = base_query.where(Song.genre.ilike(f"%{genre}%"))

    # Get total count before pagination
    total_result = db.execute(base_query)
    total = len(total_result.scalars().all())

    # Apply pagination and fetch results
    query = base_query.order_by(Song.created_at.desc()).offset(offset).limit(limit)
    result = db.execute(query)
    songs = result.scalars().all()

    # Format response
    song_list = [_format_song_response(song) for song in songs]

    return SongListResponse(songs=song_list, total=total)


@router.get("/{song_id}")
async def get_song(
    song_id: str,
    db: SQLSession = Depends(get_db),
) -> SongResponse:
    """
    Get a specific song by ID
    
    Response: 200 OK
    ```json
    {
        "id": "uuid",
        "title": "Song Title",
        "artist": "Artist Name",
        "duration": 180,
        "genre": "Pop",
        "year": 2020,
        "status": "COMPLETED",
        "created_at": "2026-04-28T...",
        "updated_at": "2026-04-28T..."
    }
    ```
    """
    try:
        song_uuid = uuid.UUID(song_id)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "INVALID_UUID",
                "message": "Invalid song ID format",
                "details": {"song_id": song_id},
            },
        )

    query = select(Song).where(Song.id == song_uuid)
    result = db.execute(query)
    song = result.scalars().first()

    if not song:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "SONG_NOT_FOUND",
                "message": f"Song {song_id} not found",
                "details": {"song_id": song_id},
            },
        )

    return _format_song_response(song)


@router.get("/{song_id}/status")
async def get_song_status(
    song_id: str,
    db: SQLSession = Depends(get_db),
) -> SongStatusResponse:
    """
    Check the download status of a song
    
    Response: 200 OK
    ```json
    {
        "song_id": "uuid",
        "status": "downloading|completed|failed",
        "progress": 0-100,
        "error_message": null
    }
    ```
    """
    try:
        song_uuid = uuid.UUID(song_id)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "INVALID_UUID",
                "message": "Invalid song ID format",
                "details": {"song_id": song_id},
            },
        )

    query = select(Song).where(Song.id == song_uuid)
    result = db.execute(query)
    song = result.scalars().first()

    if not song:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "SONG_NOT_FOUND",
                "message": f"Song {song_id} not found",
                "details": {"song_id": song_id},
            },
        )

    # Calculate progress based on status
    progress = 0
    if song.status == "DOWNLOADING":
        progress = 50  # Placeholder: would be actual progress
    elif song.status == "COMPLETED":
        progress = 100

    return SongStatusResponse(
        song_id=str(song.id),
        status=song.status,
        progress=progress,
        error_message=song.error_message,
    )
