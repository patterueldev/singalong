"""Song management API endpoints for Node"""

import uuid
import logging
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
    IdentifyRequest,
    SongMetadataResponse,
    EnhanceSongRequest,
    DownloadSongRequest,
    DownloadStatusResponse,
    SongEnhanceRequest,
    EnhancedSongMetadataResponse,
)
from app.services.graphql_client import MasterGraphQLClient, GraphQLError
from app.services.enhancement_service import EnhancementService
from app.services.yt_dlp_service import YTDLPService, YTDLPError
from app.services.song_lookup_service import SongLookupService, SongLookupError
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/songs", tags=["Songs"])


def get_db():
    """Dependency for database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/identify", response_model=SongMetadataResponse, status_code=200)
async def identify_song(request: IdentifyRequest) -> SongMetadataResponse:
    """
    Identify song metadata from YouTube URL

    Workflow:
    Step 1: Validate URL and extract video ID
    Step 2: Extract metadata from local YT-DLP
    Step 3: Return metadata for user enhancement

    Note: Master duplicate checking not yet implemented (B-phase feature)
    For now, users will receive "song already exists" error during download 
    if they try to submit a video that's already in Master.

    Args:
        request: IdentifyRequest with YouTube URL

    Returns:
        SongMetadataResponse with extracted metadata

    Raises:
        HTTPException: 
          - 400 if invalid URL
          - 403 if video is private/age-restricted
          - 404 if video not found or removed
          - 429 if request throttled by YouTube
          - 504 if request timed out
    """
    try:
        # Step 1: Validate URL format and extract video ID
        yt_dlp_validator = YTDLPService(timeout=30)
        if not yt_dlp_validator.validate_url(request.url):
            raise YTDLPError("Invalid YouTube URL format")
        
        video_id = yt_dlp_validator._extract_video_id(request.url)
        if not video_id:
            raise YTDLPError("Could not extract video ID from URL")

        logger.info(f"Identifying song: {request.url} (video_id: {video_id})")

        # Step 2: Extract metadata from local YT-DLP
        yt_dlp = YTDLPService(timeout=30)
        metadata = yt_dlp.extract_metadata(request.url)

        logger.info(f"✓ Identified: {metadata.get('title')}")
        
        # Return metadata
        return SongMetadataResponse(**metadata)

    except YTDLPError as e:
        error_str = str(e)
        logger.error(f"YT-DLP error identifying song: {error_str}")

        # Map error messages to HTTP status codes
        error_lower = error_str.lower()
        
        if "invalid youtube url" in error_str:
            raise HTTPException(
                status_code=400,
                detail="Invalid YouTube URL format",
            )
        if "unavailable" in error_lower or "not found" in error_lower or "removed" in error_lower:
            raise HTTPException(
                status_code=404,
                detail="Video not found or has been removed",
            )
        if "private" in error_lower or "age-restricted" in error_lower or "age restricted" in error_lower:
            raise HTTPException(
                status_code=403,
                detail="Video is private or age-restricted",
            )
        if "throttled" in error_lower:
            raise HTTPException(
                status_code=429,
                detail="Request throttled by YouTube. Please try again later.",
            )
        if "timed out" in error_lower:
            raise HTTPException(
                status_code=504,
                detail="Request timed out. Please try again with a different video.",
            )

        # Generic error (default to 400)
        raise HTTPException(status_code=400, detail="Failed to identify song. Please check the URL and try again.")

    except HTTPException:
        # Re-raise HTTP exceptions
        raise

    except Exception as e:
        logger.exception(f"Unexpected error identifying song: {str(e)}")
        raise HTTPException(
            status_code=500, detail="Failed to identify song. Please try again."
        )


@router.post("/enhance", response_model=SongMetadataResponse, status_code=200)
async def enhance_song(request: EnhanceSongRequest) -> SongMetadataResponse:
    """
    Enhance song metadata using AI
    
    Uses OpenAI to improve: title, artist, year, language
    
    Accepts the output from /identify endpoint and returns enhanced version.
    If OpenAI API is not configured, returns original metadata unchanged.
    
    **Request Body (from /identify output):**
    ```json
    {
      "videoId": "x_6nob9_WLc",
      "source": "youtube",
      "title": "[Karaoke 0] Aqours - 未熟DREAMER ( Mijuku DREAMER )",
      "artist": "",
      "duration": 352,
      "thumbnail": "https://i.ytimg.com/vi/x_6nob9_WLc/maxresdefault.jpg",
      "year": "",
      "language": "",
      "url": "https://www.youtube.com/watch?v=x_6nob9_WLc",
      "tags": ["aqours", "karaoke", ...]
    }
    ```
    
    **Response:**
    Same structure with improved fields: title, artist, year, language
    
    **Example Enhanced Response:**
    ```json
    {
      "videoId": "x_6nob9_WLc",
      "source": "youtube",
      "title": "Aqours - 未熟DREAMER",
      "artist": "Aqours",
      "duration": 352,
      "thumbnail": "...",
      "year": "2016",
      "language": "ja",
      "url": "...",
      "tags": [...],
      "lyrics": ""
    }
    ```
    """
    try:
        if not settings.openai_api_key:
            logger.warning("OpenAI API key not configured, returning unenhanced metadata")
            # Return unenhanced but with all fields
            return SongMetadataResponse(
                videoId=request.videoId,
                source=request.source,
                title=request.title,
                artist=request.artist,
                duration=request.duration,
                thumbnail=request.thumbnail,
                year=request.year,
                language=request.language,
                url=request.url,
                tags=request.tags,
                lyrics="",
            )

        logger.info(f"Enhancing song: {request.title}")

        # Initialize enhancement service
        enhancement_service = EnhancementService(settings.openai_api_key)

        # Fetch description from YouTube if available
        description = ""
        if request.source == "youtube":
            try:
                yt_dlp = YTDLPService(timeout=10)
                # Get just the description without full metadata
                result = yt_dlp._get_video_description(request.videoId)
                if result:
                    description = result
                    logger.info(f"Fetched YouTube description ({len(description)} chars)")
            except Exception as e:
                logger.warning(f"Could not fetch YouTube description: {str(e)}")

        # Call OpenAI to enhance metadata
        enhanced = await enhancement_service.enhance(
            title=request.title,
            artist=request.artist,
            year=request.year,
            language=request.language,
            tags=request.tags,
            description=description,
        )

        # Return full response with enhanced fields
        return SongMetadataResponse(
            videoId=request.videoId,
            source=request.source,
            title=enhanced["title"],
            artist=enhanced["artist"],
            duration=request.duration,
            thumbnail=request.thumbnail,
            year=enhanced["year"],
            language=enhanced["language"],
            url=request.url,
            tags=request.tags,
            lyrics="",
        )

    except Exception as e:
        logger.error(f"Error enhancing song: {str(e)}")
        # Graceful degradation: return original metadata
        logger.info("Returning original metadata due to enhancement error")
        return SongMetadataResponse(
            videoId=request.videoId,
            source=request.source,
            title=request.title,
            artist=request.artist,
            duration=request.duration,
            thumbnail=request.thumbnail,
            year=request.year,
            language=request.language,
            url=request.url,
            tags=request.tags,
            lyrics="",
        )


@router.post("/download-request", response_model=dict, status_code=202)
async def download_song_request(
    request: DownloadSongRequest,
) -> dict:
    """
    Request a song download to Master

    Sends enhanced metadata to Master, which starts async download.
    Returns immediately with draft song ID for progress tracking.

    Args:
        request: DownloadSongRequest with URL and metadata

    Returns:
        202 Accepted with songId and status

    Raises:
        HTTPException: 400 if invalid, 500 if server error
    """
    try:
        logger.info(f"Download request for {request.title} from {request.url}")

        graphql_client = MasterGraphQLClient(settings.master_graphql_url)

        # Call Master to request download
        response = await graphql_client.request_song_download(
            url=request.url,
            title=request.title,
            artist=request.artist,
            enhanced_metadata={"user_id": request.user_id, "reserve": request.reserve},
            requested_by_node_id="node-1",  # TODO: Get actual node ID from context
        )

        logger.info(f"Download request accepted: {response.get('songId')}")

        return {
            "songId": response.get("songId"),
            "status": response.get("status"),
            "message": response.get("message", "Download started"),
            "estimatedTime": 120,  # TODO: Improve estimation
        }

    except GraphQLError as e:
        error_str = str(e)
        logger.error(f"GraphQL error requesting download: {error_str}")

        # Map errors
        if "Invalid YouTube URL" in error_str:
            raise HTTPException(status_code=400, detail="Invalid YouTube URL")
        if "not found" in error_str.lower():
            raise HTTPException(status_code=404, detail="Video not found")

        raise HTTPException(status_code=400, detail=error_str)

    except Exception as e:
        logger.exception(f"Error requesting download: {str(e)}")
        raise HTTPException(
            status_code=500, detail="Failed to request download. Please try again."
        )




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


@router.get("/{song_id}/download-status", response_model=DownloadStatusResponse)
async def check_download_status(song_id: str) -> DownloadStatusResponse:
    """
    Check the download status of a song

    Queries Master for current download progress.

    Args:
        song_id: Draft or final song UUID

    Returns:
        DownloadStatusResponse with current status and progress

    Raises:
        HTTPException: 404 if song not found, 500 if server error
    """
    try:
        logger.info(f"Checking download status for {song_id}")

        graphql_client = MasterGraphQLClient(settings.master_graphql_url)

        # Query Master for download status
        status_data = await graphql_client.get_download_status(song_id)

        if not status_data:
            raise HTTPException(status_code=404, detail="Download not found")

        logger.info(f"Status for {song_id}: {status_data.get('status')}")

        return DownloadStatusResponse(**status_data)

    except GraphQLError as e:
        error_str = str(e)
        if "not found" in error_str.lower():
            raise HTTPException(status_code=404, detail="Song not found")
        raise HTTPException(status_code=500, detail=str(e))

    except Exception as e:
        logger.exception(f"Error checking download status: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to check status")
