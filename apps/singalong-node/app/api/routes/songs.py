"""Song management API endpoints for Node"""

import asyncio
import uuid
import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Depends, Request
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.orm import Session as SQLSession
import os

from app.database import SessionLocal
from app.models.db_models import Song, DownloadQueue
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
from app.middleware.auth import verify_bearer_token

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
async def identify_song(request: IdentifyRequest, enhance: bool = Query(False), token: dict = Depends(verify_bearer_token)) -> SongMetadataResponse:
    """
    Identify song metadata from YouTube URL

    Workflow:
    Step 0: Validate URL and extract video ID
    Step 1: Extract metadata from local YT-DLP
    Step 2: (Optional) Enhance metadata using OpenAI agent
    Step 3: Return metadata for user review/modification

    Note: We intentionally allow re-identification of songs. Users can identify
    the same video multiple times to fix/update metadata. The download endpoint
    will handle overwriting existing records if needed.

    Query Parameters:
        enhance: bool (default: False)
            - True: Automatically enhance metadata using OpenAI agent
            - False: Return raw YT-DLP metadata (faster, no API cost)
            
    Enhancement Fallback:
        If OpenAI enhancement fails (API key missing, quota exceeded, etc.),
        gracefully returns raw metadata instead of failing the entire request.

    Args:
        request: IdentifyRequest with YouTube URL
        enhance: bool, whether to auto-enhance using OpenAI (default: False)

    Returns:
        SongMetadataResponse with extracted metadata (enhanced if requested)

    Raises:
        HTTPException: 
          - 400 if invalid URL
          - 403 if video is private/age-restricted
          - 404 if video not found or removed
          - 429 if request throttled by YouTube
          - 504 if request timed out
    """
    try:
        logger.info(f"▶ [IDENTIFY START] URL: {request.url} | enhance={enhance}")
        
        # Step 0: Validate URL and extract video ID
        logger.debug(f"  → Validating URL...")
        yt_dlp_validator = YTDLPService(timeout=30)
        if not yt_dlp_validator.validate_url(request.url):
            raise YTDLPError("Invalid YouTube URL format")
        
        video_id = yt_dlp_validator._extract_video_id(request.url)
        if not video_id:
            raise YTDLPError("Could not extract video ID from URL")

        logger.info(f"  ✓ Video ID extracted: {video_id}")

        # Note: We intentionally do NOT check for existing videos on Master.
        # This allows users to "re-identify" songs to fix or update their metadata.
        # The download endpoint will handle overwriting existing records.

        # Step 1: Validate URL format and extract video ID (already done above)

        # Step 2: Extract metadata from local YT-DLP
        logger.debug(f"  → Calling yt-dlp to extract metadata...")
        yt_dlp = YTDLPService(timeout=30)
        metadata = yt_dlp.extract_metadata(request.url)

        logger.info(f"  ✓ Metadata extracted from yt-dlp")
        logger.info(f"    Title: {metadata.get('title')}")
        logger.info(f"    Duration: {metadata.get('duration')}s | Language: {metadata.get('language')}")
        
        # Step 3: Optionally enhance metadata using OpenAI
        if enhance:
            try:
                logger.info(f"  → Starting enhancement with OpenAI...")
                
                # Fetch description from YouTube
                description = None
                try:
                    logger.debug(f"    → Fetching YouTube description...")
                    description = yt_dlp._get_video_description(video_id)
                    if description:
                        metadata["description"] = description
                        logger.info(f"    ✓ YouTube description fetched ({len(description)} chars)")
                except Exception as e:
                    logger.warning(f"    ✗ Could not fetch YouTube description: {str(e)}")
                
                # Use OpenAI agent to enhance
                if settings.openai_api_key:
                    logger.debug(f"    → Calling OpenAI enhancement service...")
                    enhancement_service = EnhancementService(settings.openai_api_key)
                    enhanced = await enhancement_service.enhance(metadata)
                    metadata = enhanced
                    logger.info(f"  ✓ Enhancement complete")
                    logger.info(f"    Title: {metadata.get('title')}")
                    logger.info(f"    Artist: {metadata.get('artist')} | Year: {metadata.get('year')}")
                else:
                    logger.warning("  ✗ OpenAI API key not configured, skipping enhancement")
                    
            except Exception as e:
                # Graceful degradation: log warning but return original metadata
                logger.warning(f"  ✗ Enhancement failed (returning original): {str(e)}")
                # metadata already contains raw YT-DLP data, just continue
        
        logger.info(f"◀ [IDENTIFY END] Returning metadata for: {metadata.get('title')}")
        # Return metadata (raw or enhanced)
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
async def enhance_song(request: EnhanceSongRequest, token: dict = Depends(verify_bearer_token)) -> SongMetadataResponse:
    """
    Enhance song metadata using OpenAI agent with function calling.
    
    Uses OpenAI to intelligently coordinate multiple research tools:
    - parse_title: Extract artist and title from YouTube title
    - search_musicbrainz: Verify artist, year from official database
    - detect_language: Identify song language
    - search_lyrics: Get lyrics for context
    
    The agent decides which tools to call based on what's missing/unclear.
    
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
    """
    try:
        logger.info(f"▶ [ENHANCE START] Title: {request.title} | Video ID: {request.videoId}")
        
        if not settings.openai_api_key:
            logger.warning("  ✗ OpenAI API key not configured, returning original metadata")
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

        logger.debug(f"  → Converting request to metadata dict...")

        # Convert request to metadata dict
        metadata = {
            "videoId": request.videoId,
            "source": request.source,
            "title": request.title,
            "artist": request.artist,
            "duration": request.duration,
            "thumbnail": request.thumbnail,
            "year": request.year,
            "language": request.language,
            "url": request.url,
            "tags": request.tags,
            "lyrics": getattr(request, "lyrics", ""),
        }

        # Fetch description from YouTube if available
        if request.source == "youtube":
            try:
                logger.debug(f"  → Fetching YouTube description...")
                yt_dlp = YTDLPService(timeout=10)
                description = yt_dlp._get_video_description(request.videoId)
                if description:
                    metadata["description"] = description
                    logger.info(f"  ✓ YouTube description fetched ({len(description)} chars)")
            except Exception as e:
                logger.warning(f"  ✗ Could not fetch YouTube description: {str(e)}")

        # Use OpenAI agent to enhance metadata
        logger.debug(f"  → Calling OpenAI enhancement service...")
        enhancement_service = EnhancementService(settings.openai_api_key)
        enhanced = await enhancement_service.enhance(metadata)
        logger.info(f"  ✓ OpenAI enhancement complete")
        logger.info(f"    Title: {enhanced.get('title')} | Artist: {enhanced.get('artist')} | Year: {enhanced.get('year')}")

        logger.info(f"◀ [ENHANCE END] Enhanced: {enhanced.get('title')}")
        
        # Return full response with enhanced fields
        return SongMetadataResponse(
            videoId=enhanced.get("videoId", request.videoId),
            source=enhanced.get("source", request.source),
            title=enhanced.get("title", request.title),
            artist=enhanced.get("artist", request.artist),
            duration=enhanced.get("duration", request.duration),
            thumbnail=enhanced.get("thumbnail", request.thumbnail),
            year=enhanced.get("year", request.year),
            language=enhanced.get("language", request.language),
            url=enhanced.get("url", request.url),
            tags=enhanced.get("tags", request.tags),
            lyrics=enhanced.get("lyrics", ""),
        )

    except Exception as e:
        logger.error(f"✗ [ENHANCE ERROR] {str(e)}", exc_info=True)
        # Graceful degradation: return original metadata
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
    token: dict = Depends(verify_bearer_token),
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
    token: dict = Depends(verify_bearer_token),
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
    token: dict = Depends(verify_bearer_token),
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


@router.post("/download", response_model=DownloadStatusResponse, status_code=202)
async def download_song(
    request: SongMetadataResponse,
    reserve: bool = Query(False),
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> DownloadStatusResponse:
    """
    Request to download a song from Master.
    
    This is the final step in the workflow:
    1. User identifies song via /api/songs/identify
    2. (Optional) User enhances metadata via /api/songs/enhance
    3. User submits to /api/songs/download to start download
    
    The endpoint:
    - Allows re-downloading the same video (replaces existing draft)
    - Calls Master GraphQL mutation: requestSongDownload
    - Returns immediately (async download on Master)
    - Stores local tracking record
    
    Note: If the same videoId is downloaded multiple times, previous drafts
    are deleted and a new draft is created. This allows fixing corrupted 
    downloads or updating metadata without manual cleanup (MVP approach).
    
    Query Parameters:
        reserve: bool (default: False)
            - True: Reserve song after download completes (B8, placeholder for now)
            - False: Just download, no reservation
    
    Request Body: SongMetadataResponse (from /identify or /enhance)
    
    Returns:
        DownloadStatusResponse with download_id, status='queued'
    
    Status Code:
        202 Accepted: Download request queued (async, not waiting for completion)
    
    Error Codes:
        400 Bad Request: Invalid metadata
        500 Internal Server Error: Master unreachable or download failed
    """
    try:
        logger.info(f"▶ [DOWNLOAD START] Title: {request.title} | Video ID: {request.videoId} | Reserve: {reserve}")

        # Step 1: Validate metadata
        logger.debug(f"  → Validating metadata...")
        if not request.videoId:
            raise ValueError("videoId is required")
        if not request.source:
            raise ValueError("source is required (e.g., 'youtube')")
        if not request.url:
            raise ValueError("url is required")
        logger.debug(f"  ✓ Metadata validation passed")

        # Step 2: Call Master GraphQL requestSongDownload mutation using existing client method
        logger.info(f"  → Calling Master GraphQL requestSongDownload mutation...")
        master_client = MasterGraphQLClient(settings.master_graphql_url)
        
        logger.debug(f"    → Preparing mutation variables...")
        
        # Call the mutation directly with correct parameters matching Master schema
        mutation_query = """
            mutation requestSongDownload(
                $videoId: String!
                $source: String!
                $title: String!
                $artist: String!
                $year: String!
                $language: String!
                $duration: Int!
                $thumbnail: String!
                $url: String!
                $tags: [String!]!
                $lyrics: String!
                $requestedByNodeId: String!
            ) {
                requestSongDownload(
                    videoId: $videoId
                    source: $source
                    title: $title
                    artist: $artist
                    year: $year
                    language: $language
                    duration: $duration
                    thumbnail: $thumbnail
                    url: $url
                    tags: $tags
                    lyrics: $lyrics
                    requestedByNodeId: $requestedByNodeId
                ) {
                    songId
                    status
                    progress
                    message
                    error
                }
            }
        """

        variables = {
            "videoId": request.videoId,
            "source": request.source,
            "title": request.title,
            "artist": request.artist,
            "year": request.year,
            "language": request.language,
            "duration": int(request.duration) if request.duration else 0,
            "thumbnail": request.thumbnail,
            "url": request.url,
            "tags": request.tags,
            "lyrics": request.lyrics or "",
            "requestedByNodeId": settings.node_id,
        }
        logger.debug(f"    ✓ Variables prepared: {variables}")

        # Execute mutation
        logger.debug(f"    → Executing GraphQL mutation...")
        download_data = await master_client._execute_mutation(mutation_query, variables)
        logger.debug(f"    ✓ Master response received: {download_data}")
        
        download_id = download_data.get("requestSongDownload", {}).get("songId")
        status = download_data.get("requestSongDownload", {}).get("status", "queued")

        if not download_id:
            error_msg = download_data.get("requestSongDownload", {}).get("error", "Unknown error")
            logger.error(f"  ✗ Master rejected download: {error_msg}")
            raise ValueError(f"Master error: {error_msg}")

        logger.info(f"  ✓ Master accepted download request")
        logger.info(f"    Song ID: {download_id} | Status: {status}")

        # Step 3: Store local tracking record
        logger.debug(f"  → Creating local download queue entry...")
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        entry = download_service.create_download_queue_entry(
            video_id=request.videoId,
            title=request.title,
            master_download_id=download_id,
            status=status,
        )
        logger.info(f"  ✓ Local download queue entry created: {entry['download_id']}")

        # Step 4: Placeholder for reservation
        if reserve:
            logger.info(f"  → Reserve flag set (placeholder for B8)")
            # TODO: B8 - Implement actual reservation logic

        logger.info(f"◀ [DOWNLOAD END] Download queued: {request.title} (songId: {download_id})")
        
        # Return 202 Accepted (download queued, not waiting)
        return DownloadStatusResponse(
            song_id=download_id,
            status=status,
            progress=0,
            message="Download queued on Master",
            error=None,
        )

    except ValueError as e:
        logger.error(f"✗ [DOWNLOAD VALIDATION ERROR] {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

    except GraphQLError as e:
        error_str = str(e)
        logger.error(f"✗ [DOWNLOAD GRAPHQL ERROR] {error_str}")

        if "already" in error_str.lower():
            raise HTTPException(
                status_code=409,
                detail=f"Song already requested: {error_str}",
            )

        raise HTTPException(status_code=500, detail=f"Master error: {error_str}")

    except Exception as e:
        logger.exception(f"✗ [DOWNLOAD EXCEPTION] {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to request download")


@router.get("/downloads", response_model=list, status_code=200)
async def get_active_downloads(
    status_filter: str = Query(None, alias="status"),
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> list:
    """
    Get list of active song downloads being tracked by this Node.
    
    This endpoint shows:
    - Downloads queued on Master (awaiting YT-DLP download)
    - Downloads in progress on Master
    - Downloads completed (synced to Node in B3)
    
    Query Parameters:
        status: (optional) Filter by status
            - pending: Queued, not yet downloading
            - downloading: YT-DLP download in progress
            - completed: Downloaded and synced to Node
            - failed: Download failed
    
    Returns:
        Array of DownloadStatusResponse objects
    
    Status Code: 200 OK
    """
    try:
        logger.info(f"Listing active downloads (status={status_filter})")

        # Step 1: Get local tracking records
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        downloads = download_service.get_active_downloads()

        # Step 2: Query Master for latest status on each
        master_client = MasterGraphQLClient(settings.master_graphql_url)

        updated_downloads = []
        for download in downloads:
            try:
                # Query Master for latest status using existing method
                status_data = await master_client.get_download_status(
                    download.get("master_download_id")
                )

                if status_data:
                    download_status = status_data.get("status", "unknown")

                    # Update local DownloadQueue record to reflect Master's status
                    try:
                        from uuid import UUID
                        download_uuid = UUID(download.get("download_id"))
                        local_download = db.query(DownloadQueue).filter(
                            DownloadQueue.id == download_uuid
                        ).first()
                        if local_download:
                            old_status = local_download.status
                            local_download.status = download_status
                            local_download.progress = status_data.get("progress", 0)
                            local_download.file_path = status_data.get("filePath")
                            local_download.error_message = status_data.get("error")
                            db.commit()
                            if old_status != download_status:
                                logger.info(f"Updated {download.get('video_id')} status: {old_status} → {download_status}")
                    except Exception as e:
                        logger.warning(f"Could not update local download record: {str(e)}")

                    # Filter by status if requested
                    if status_filter and download_status != status_filter:
                        continue

                    updated_downloads.append(
                        {
                            "download_id": download.get("download_id"),
                            "videoId": download.get("video_id"),
                            "title": download.get("title"),
                            "status": download_status,
                            "progress_percent": status_data.get("progress", 0),
                            "created_at": download.get("created_at"),
                            "completed_at": None,
                            "file_path": status_data.get("filePath"),
                            "error_message": status_data.get("error"),
                        }
                    )
            except Exception as e:
                logger.warning(f"Could not query Master for {download.get('master_download_id')}: {str(e)}")
                updated_downloads.append(download)

        logger.info(f"Found {len(updated_downloads)} active downloads")
        return updated_downloads

    except Exception as e:
        logger.exception(f"Error listing downloads: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to list downloads")


@router.post("/downloads/{download_id}/retry", status_code=200)
async def retry_failed_download(
    download_id: str,
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    Retry a failed download by resetting it to pending status.
    
    This endpoint allows users to retry a download that previously failed
    (e.g., due to network issues, timeout, etc).
    
    Path Parameters:
        download_id: UUID of the failed download
    
    Returns:
        200 OK: Retry queued
        400 Bad Request: Download not in failed state
        404 Not Found: Download not found
        500 Internal Server Error: Operation failed
    """
    try:
        logger.info(f"Retry requested for download: {download_id}")
        
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        
        result = download_service.retry_failed_download(download_id)
        
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        
        return result
        
    except HTTPException:
        # Re-raise HTTPException without catching it
        raise
    except ValueError as e:
        logger.error(f"Invalid download ID: {str(e)}")
        raise HTTPException(status_code=404, detail="Download not found")
    except Exception as e:
        logger.exception(f"Error retrying download: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retry download")


@router.delete("/downloads/{download_id}", status_code=200)
async def delete_download(
    download_id: str,
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    Delete/remove a download from the queue.
    
    Useful for cleaning up failed downloads or canceling pending ones.
    This does NOT delete the actual video file if already downloaded.
    
    Path Parameters:
        download_id: UUID of the download to delete
    
    Returns:
        200 OK: Download removed
        404 Not Found: Download not found
        500 Internal Server Error: Operation failed
    """
    try:
        logger.info(f"Delete requested for download: {download_id}")
        
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        
        result = download_service.delete_download(download_id)
        
        if "error" in result:
            raise HTTPException(status_code=404, detail=result["error"])
        
        return result
        
    except HTTPException:
        # Re-raise HTTPException without catching it
        raise
    except ValueError as e:
        logger.error(f"Invalid download ID: {str(e)}")
        raise HTTPException(status_code=404, detail="Download not found")
    except Exception as e:
        logger.exception(f"Error deleting download: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete download")


@router.post("/downloads/cleanup", status_code=200)
async def cleanup_old_downloads(
    hours: int = Query(1, ge=0, le=24),
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    Clean up (remove) failed downloads older than specified hours.
    
    Admin-only operation to remove stale failed downloads from the queue.
    
    Query Parameters:
        hours: Age threshold in hours (0-24, default: 1)
    
    Returns:
        200 OK: Cleanup completed
        403 Forbidden: Not authorized (admin only, in future)
        500 Internal Server Error: Operation failed
    """
    try:
        logger.info(f"Cleanup requested for downloads older than {hours} hour(s)")
        
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        
        deleted_count = download_service.cleanup_old_failed_downloads(hours=hours)
        
        return {
            "deleted_count": deleted_count,
            "message": f"Removed {deleted_count} failed downloads older than {hours} hour(s)",
        }
        
    except HTTPException:
        # Re-raise HTTPException without catching it
        raise
    except Exception as e:
        logger.exception(f"Error cleaning up downloads: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to cleanup downloads")


@router.post("/downloads/clear-pending", status_code=200)
async def clear_pending_downloads(
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    DANGEROUS: Immediately remove ALL pending and in-progress downloads.
    
    Use this to reset the download queue after crashes or when old test data 
    is blocking new downloads. This will force-clear all queued downloads 
    regardless of age or status.
    
    Warning: This is a destructive operation and cannot be undone.
    
    Returns:
        200 OK: All pending downloads cleared
        500 Internal Server Error: Operation failed
    """
    try:
        logger.warning("ADMIN OPERATION: Force-clearing all pending downloads")
        
        from app.services.node_download_service import NodeDownloadService
        download_service = NodeDownloadService(db)
        
        deleted_count = download_service.clear_pending_downloads()
        
        return {
            "deleted_count": deleted_count,
            "message": f"Force-cleared {deleted_count} pending/in_progress downloads from queue",
            "warning": "This operation removed all pending downloads without waiting for completion",
        }
        
    except HTTPException:
        # Re-raise HTTPException without catching it
        raise
    except Exception as e:
        logger.exception(f"Error clearing pending downloads: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to clear pending downloads")


@router.get("/video/{video_id}", status_code=200)
async def stream_video(
    video_id: str,
    request: Request,
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
):
    """
    Stream a video file for a synced song.
    
    The video file is stored on Master but accessed through Node's public URL.
    This allows clients to fetch videos using the Node's URL without needing
    to know about Master's internal structure.
    
    Path Parameters:
        video_id: YouTube video ID
    
    Returns:
        200 OK: Video file (mp4) with streaming support
        404 Not Found: Video not found
    """
    try:
        # Look up song by video_id to get file_path
        song = db.query(Song).filter(Song.video_id == video_id).first()
        
        if not song or not song.file_path:
            logger.warning(f"Video not found: {video_id}")
            raise HTTPException(status_code=404, detail="Video not found")
        
        # Verify file exists
        if not os.path.exists(song.file_path):
            logger.error(f"Video file missing: {song.file_path}")
            raise HTTPException(status_code=404, detail="Video file not accessible")
        
        logger.info(f"Streaming video: {video_id} from {song.file_path}")
        
        # Stream the file
        return FileResponse(
            path=song.file_path,
            media_type="video/mp4",
            filename=os.path.basename(song.file_path),
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error streaming video {video_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to stream video")


@router.get("/songbook", response_model=dict)
async def get_songbook(
    search: Optional[str] = Query(None, description="Search by title or artist"),
    limit: int = Query(10, ge=1, le=100, description="Results per page"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    sort: str = Query("title", regex="^(title|artist|year)$", description="Sort field"),
    sessionId: Optional[str] = Query(None, description="Session ID to check reservation status"),
    db: SQLSession = Depends(get_db),
    request: Request = None,
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    Get synced songs from Node's local database (songbook).

    Returns songs that have been synced via POST /api/songs/sync.
    Only returns ACTIVE songs (not archived or corrupted).

    No Master queries - instant response using local cache.

    Query Parameters:
    - search: Filter by title or artist (case-insensitive, optional)
    - limit: Results per page (1-100, default 10)
    - offset: Pagination offset (default 0)
    - sort: Sort order - title, artist, or year (default: title)
    - sessionId: Session ID to check reservation status (optional, returns isReserved field)

    Returns:
    {
        "songs": [
            {
                "id": "uuid",
                "title": "Song Title",
                "artist": "Artist Name",
                "duration": 180,
                "year": 2020,
                "thumbnail": "https://...",
                "status": "ACTIVE",
                "isReserved": true or false or null  (null if sessionId not provided)
            }
        ],
        "total": 142,
        "limit": 10,
        "offset": 0,
        "hasMore": true
    }
    """
    from sqlalchemy import or_, desc

    try:
        # Query all ACTIVE songs from local database
        query = db.query(Song).filter(Song.status == "ACTIVE")

        # Apply search filter if provided
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                or_(
                    Song.title.ilike(search_term),
                    Song.artist.ilike(search_term),
                )
            )

        # Get total count before pagination
        total = query.count()

        # Apply sorting
        if sort == "title":
            query = query.order_by(Song.title)
        elif sort == "artist":
            query = query.order_by(Song.artist)
        elif sort == "year":
            query = query.order_by(desc(Song.year))

        # Apply pagination
        songs = query.limit(limit).offset(offset).all()

        # Build reservation lookup if sessionId provided
        reserved_song_ids = set()
        if sessionId:
            from uuid import UUID as UUID_type
            from app.models.db_models import Reservation
            
            try:
                session_uuid = UUID_type(sessionId)
                reserved_songs = db.query(Reservation.song_id).filter(
                    Reservation.session_id == session_uuid
                ).all()
                reserved_song_ids = {str(r[0]) for r in reserved_songs}
            except (ValueError, Exception) as e:
                logger.warning(f"Could not check reservation status for session {sessionId}: {str(e)}")

        # Build response with videoUrl using request's host
        song_list = []
        for song in songs:
            # Construct video URL using the request's origin
            video_url = None
            if song.video_id:
                try:
                    # Use request.base_url which includes scheme and host
                    if request:
                        base_url = str(request.base_url).rstrip('/')
                        video_url = f"{base_url}/api/songs/video/{song.video_id}"
                    else:
                        # Fallback if request is not available
                        logger.warning("Request object not available in songbook endpoint")
                        video_url = f"/api/songs/video/{song.video_id}"
                except Exception as e:
                    logger.error(f"Error constructing video URL: {str(e)}")
                    video_url = f"/api/songs/video/{song.video_id}"
            
            song_list.append({
                "id": str(song.id),
                "title": song.title,
                "artist": song.artist,
                "duration": song.duration,
                "year": song.year,
                "source": song.source,
                "videoId": song.video_id,
                "thumbnail": song.thumbnail,
                "status": song.status,
                "syncedAt": song.synced_at.isoformat() if song.synced_at else None,
                "isReserved": str(song.id) in reserved_song_ids if sessionId else None,
                "videoUrl": video_url,
            })

        return {
            "songs": song_list,
            "total": total,
            "limit": limit,
            "offset": offset,
            "hasMore": offset + limit < total,
        }

    except Exception as e:
        logger.error(f"Error fetching songbook: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to fetch songbook")


@router.get("/{song_id}")
async def get_song(
    song_id: str,
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
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
    token: dict = Depends(verify_bearer_token),
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
async def check_download_status(song_id: str, token: dict = Depends(verify_bearer_token)) -> DownloadStatusResponse:
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


@router.post("/sync", status_code=202)
async def sync_songs_from_master(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    db: SQLSession = Depends(get_db),
    token: dict = Depends(verify_bearer_token),
) -> dict:
    """
    Trigger song sync from Master to Node.

    Pulls ACTIVE songs from Master's database, downloads video files,
    and updates Node's local song database. Runs asynchronously in background.

    Returns immediately (202 Accepted) with task status. Sync continues
    in background and Node's songbook will be updated as songs complete.

    Query Parameters:
    - limit: Number of songs to sync per batch (default: 100, max: 1000)
    - offset: Starting position for pagination (default: 0)

    Returns:
    {
        "status": "queued",
        "message": "Sync started in background",
        "limit": 100,
        "offset": 0,
        "task_id": "optional-task-id-for-future-polling"
    }
    """
    import threading

    from app.services.node_sync_service import NodeSyncService

    def _sync_background():
        """Run sync in background thread"""
        db_session = SessionLocal()
        try:
            logger.info(f"Background sync started (limit={limit}, offset={offset})")
            sync_service = NodeSyncService(db_session)
            # Use asyncio.run() to execute async method in thread
            result = asyncio.run(sync_service.sync_songs_from_master(limit=limit, offset=offset))
            logger.info(f"Background sync complete: {result.to_dict()}")
        except Exception as e:
            logger.error(f"Background sync failed: {str(e)}", exc_info=True)
        finally:
            db_session.close()

    # Start sync in background thread (fire-and-forget for MVP)
    thread = threading.Thread(target=_sync_background, daemon=True)
    thread.start()

    task_id = str(uuid.uuid4())
    return {
        "status": "queued",
        "message": "Song sync started in background",
        "limit": limit,
        "offset": offset,
        "task_id": task_id,
    }



