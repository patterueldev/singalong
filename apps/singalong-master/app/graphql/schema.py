"""GraphQL schema definition for user authentication and song operations"""

from ariadne import graphql_sync, make_executable_schema, MutationType, QueryType, ObjectType
from app.services.yt_dlp_service import YTDLPService, YTDLPError
from app.database import SessionLocal


def get_role_string(user_role):
    """Extract role as plain string, avoiding enum serialization"""
    if user_role is None:
        return "player"
    # Map enum to string explicitly
    role_map = {
        "superadmin": "superadmin",
        "admin": "admin",
        "player": "player",
        "controller": "controller",
    }
    role_str = user_role.value if hasattr(user_role, "value") else str(user_role)
    return role_map.get(role_str, "player")


# GraphQL schema
type_defs = """
    type User {
        id: String!
        username: String
        role: String!
        nickname: String
    }

    type AuthResponse {
        token: String!
        refreshToken: String!
        user: User!
    }

    type SongMetadata {
        videoId: String!
        title: String!
        artist: String
        duration: Int
        thumbnail: String
        year: String
        channel: String
        language: String
        description: String
        viewCount: Int
        url: String!
    }

    type DownloadResponse {
        songId: String!
        status: String!
        progress: Int!
        message: String
        error: String
        filePath: String
    }

    type SyncSong {
        id: String!
        title: String!
        artist: String
        duration: Int
        year: Int
        source: String
        videoId: String
        thumbnail: String
        filePath: String
        status: String!
    }

    type SyncSongsResponse {
        songs: [SyncSong!]!
        total: Int!
        limit: Int!
        offset: Int!
    }

    type Query {
        hello: String!
        identifySong(url: String!): SongMetadata!
        downloadStatus(songId: String!): DownloadResponse!
        checkVideoExists(videoId: String!): Boolean!
        activeSongs(limit: Int, offset: Int): SyncSongsResponse!
    }

    type Mutation {
        authenticateController(
            nickname: String!
            sessionId: String!
            nodeId: String!
        ): AuthResponse!
        
        authenticateAdmin(
            username: String!
            password: String!
            nodeId: String!
        ): AuthResponse!
        
        authenticatePlayer(
            sessionId: String!
            nodeId: String!
        ): AuthResponse!

        requestSongDownload(
            videoId: String!
            source: String!
            title: String!
            artist: String!
            year: String!
            language: String!
            duration: Int!
            thumbnail: String!
            url: String!
            tags: [String!]!
            lyrics: String!
            requestedByNodeId: String!
        ): DownloadResponse!
    }
"""

# Mutation resolvers
mutation = MutationType()

# Query resolvers
query = QueryType()


@query.field("hello")
def resolve_hello(obj, info):
    """Hello world query"""
    return "Hello from Master GraphQL!"


@query.field("identifySong")
def resolve_identify_song(obj, info, url: str):
    """Extract metadata from YouTube URL"""
    try:
        yt_dlp = YTDLPService(timeout=30)
        metadata = yt_dlp.extract_metadata(url)
        return metadata
    except YTDLPError as e:
        raise ValueError(f"Failed to identify song: {str(e)}")
    except Exception as e:
        raise ValueError(f"Unexpected error: {str(e)}")


@query.field("downloadStatus")
def resolve_download_status(obj, info, songId: str):
    """Get the status of a download"""
    db = SessionLocal()
    try:
        from uuid import UUID
        from app.models.db_models import DraftSong

        try:
            song_uuid = UUID(songId)
        except ValueError:
            raise ValueError("Invalid song ID format")

        draft = db.query(DraftSong).filter(DraftSong.id == song_uuid).first()

        if not draft:
            raise ValueError("Download not found")

        return {
            "songId": str(draft.id),
            "status": draft.status,
            "progress": int(draft.download_progress),
            "message": f"Download {draft.status}",
            "error": draft.error_message,
            "filePath": draft.file_path,
        }

    except ValueError as e:
        raise ValueError(str(e))
    except Exception as e:
        raise ValueError(f"Failed to get download status: {str(e)}")
    finally:
        db.close()


@query.field("checkVideoExists")
def resolve_check_video_exists(obj, info, videoId: str):
    """Check if a video with the given ID already exists on Master"""
    from app.services.master_song_service import MasterSongService
    
    db = SessionLocal()
    try:
        service = MasterSongService(db)
        exists = service.check_video_exists(videoId)
        return exists
    except Exception as e:
        raise ValueError(f"Failed to check if video exists: {str(e)}")
    finally:
        db.close()


@query.field("activeSongs")
def resolve_active_songs(obj, info, limit: int = 100, offset: int = 0):
    """
    Get ACTIVE songs for Node syncing.
    
    Returns paginated list of songs that have been successfully downloaded.
    Used by Node to sync its local song database.
    """
    from app.services.master_song_service import MasterSongService
    from sqlalchemy import and_
    
    db = SessionLocal()
    try:
        # Query all ACTIVE DraftSong records (completed downloads)
        from app.models.db_models import DraftSong
        
        query = db.query(DraftSong).filter(
            DraftSong.status == "completed"
        ).order_by(DraftSong.title)
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        songs = query.limit(limit).offset(offset).all()
        
        # Build response
        song_list = [
            {
                "id": str(s.id),
                "title": s.title,
                "artist": s.artist,
                "duration": s.duration,
                "year": None,  # DraftSong doesn't have year field
                "source": "youtube",
                "videoId": s.video_id,
                "thumbnail": None,  # DraftSong doesn't have thumbnail field
                "filePath": s.file_path,
                "status": "ACTIVE",
            }
            for s in songs
        ]
        
        return {
            "songs": song_list,
            "total": total,
            "limit": limit,
            "offset": offset,
        }
    except Exception as e:
        import logging
        logging.error(f"Error fetching active songs: {str(e)}", exc_info=True)
        raise ValueError(f"Failed to fetch active songs: {str(e)}")
    finally:
        db.close()


@mutation.field("authenticateController")
def resolve_authenticate_controller(obj, info, nickname, sessionId, nodeId):
    """Authenticate controller user"""
    from app.services.user_auth_service import UserAuthService
    
    db = SessionLocal()
    try:
        user_auth = UserAuthService()
        access_token, refresh_token, _, _, user = user_auth.authenticate_controller(
            db, nickname, sessionId, nodeId
        )
        return {
            "token": access_token,
            "refreshToken": refresh_token,
            "user": {
                "id": str(user.id),
                "username": user.username,
                "role": get_role_string(user.role),
                "nickname": user.username,
            },
        }
    except ValueError as e:
        raise ValueError(str(e))
    finally:
        db.close()


@mutation.field("authenticateAdmin")
def resolve_authenticate_admin(obj, info, username, password, nodeId):
    """Authenticate admin user"""
    from app.services.user_auth_service import UserAuthService
    
    db = SessionLocal()
    try:
        user_auth = UserAuthService()
        access_token, refresh_token, _, _, user = user_auth.authenticate_admin(
            db, username, password, nodeId
        )
        return {
            "token": access_token,
            "refreshToken": refresh_token,
            "user": {
                "id": str(user.id),
                "username": user.username,
                "role": get_role_string(user.role),
                "nickname": None,
            },
        }
    except ValueError as e:
        raise ValueError(str(e))
    finally:
        db.close()


@mutation.field("authenticatePlayer")
def resolve_authenticate_player(obj, info, sessionId, nodeId):
    """Authenticate player"""
    from app.services.user_auth_service import UserAuthService
    
    db = SessionLocal()
    try:
        user_auth = UserAuthService()
        access_token, refresh_token, _, _, user = user_auth.authenticate_player(
            db, sessionId, nodeId
        )
        return {
            "token": access_token,
            "refreshToken": refresh_token,
            "user": {
                "id": str(user.id),
                "username": None,
                "role": get_role_string(user.role),
                "nickname": None,
            },
        }
    except ValueError as e:
        raise ValueError(str(e))
    finally:
        db.close()


@mutation.field("requestSongDownload")
def resolve_request_song_download(
    obj,
    info,
    videoId: str,
    source: str,
    title: str,
    artist: str,
    year: str,
    language: str,
    duration: int,
    thumbnail: str,
    url: str,
    tags: list,
    lyrics: str,
    requestedByNodeId: str = "unknown",
):
    """
    Request a song download from Node.
    
    Creates draft record and starts async YT-DLP download in background.
    If a draft already exists for this videoId, it will be deleted and recreated.
    This allows users to "re-download" songs to fix or update metadata (MVP simplification).
    
    Args:
        videoId: YouTube video ID (11 chars)
        source: Source type (currently "youtube")
        title: Song title
        artist: Artist name
        year: Release year
        language: ISO 639-1 language code
        duration: Duration in seconds
        thumbnail: Thumbnail URL
        url: YouTube URL
        tags: List of tags
        lyrics: Song lyrics (empty string for now)
        requestedByNodeId: Node ID requesting download
    
    Returns:
        DownloadResponse with songId, status, progress
    """
    db = SessionLocal()
    try:
        import logging
        from app.utils.file_naming import generate_filename
        from app.services.master_song_service import MasterSongService
        from app.services.master_download_service import MasterDownloadService
        from app.models.db_models import DraftSong
        import asyncio
        
        logger = logging.getLogger(__name__)
        
        # Step 1: Check if draft already exists for this videoId and delete it
        # This allows users to "re-download" songs to fix/update them (MVP simplification)
        song_service = MasterSongService(db)
        existing_draft = db.query(DraftSong).filter(DraftSong.video_id == videoId).first()
        if existing_draft:
            logger.info(f"Removing existing draft for video {videoId} to allow re-download")
            db.delete(existing_draft)
            db.commit()
        
        # Step 2: Generate filename
        filename = generate_filename(title, videoId)
        logger.info(f"Generated filename: {filename}")
        
        # Step 3: Create draft song record
        draft = song_service.create_draft_song(
            video_id=videoId,
            title=title,
            artist=artist,
            year=year,
            language=language,
            duration=duration,
            thumbnail=thumbnail,
            url=url,
            tags=tags,
            lyrics=lyrics,
            requested_by_node_id=requestedByNodeId,
            enhanced_metadata=None,
        )
        
        logger.info(f"Created draft song: {draft.id}")
        
        # Step 4: Start async download in background
        # Fire-and-forget: don't wait for completion
        def background_download():
            try:
                logger.info(f"Starting background download for {videoId}")
                
                # Update status to downloading
                song_service.update_draft_status(
                    str(draft.id),
                    status="downloading",
                    progress=0,
                )
                
                # Download video
                download_service = MasterDownloadService()
                file_path, error_msg = download_service.download_video_sync(
                    video_id=videoId,
                    filename=filename,
                    timeout=300,
                )
                
                # Update final status
                if file_path:
                    file_size = download_service.get_file_size(file_path)
                    song_service.update_draft_status(
                        str(draft.id),
                        status="completed",
                        progress=100,
                        file_path=file_path,
                        file_size=str(file_size),
                    )
                    logger.info(f"✓ Download completed: {file_path}")
                else:
                    song_service.update_draft_status(
                        str(draft.id),
                        status="failed",
                        progress=0,
                        error_message=error_msg,
                    )
                    logger.error(f"✗ Download failed: {error_msg}")
                    
            except Exception as e:
                logger.exception(f"Background download error: {str(e)}")
                try:
                    song_service.update_draft_status(
                        str(draft.id),
                        status="failed",
                        error_message=str(e),
                    )
                except:
                    pass
        
        # Start download in background thread
        import threading
        thread = threading.Thread(target=background_download, daemon=True)
        thread.start()
        
        # Return immediate response (don't wait for download)
        return {
            "songId": str(draft.id),
            "status": "queued",
            "progress": 0,
            "message": "Download queued. Monitor progress via downloadStatus query.",
            "error": None,
        }
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise ValueError(str(e))
    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        raise ValueError(f"Failed to request download: {str(e)}")
    finally:
        db.close()


# Build executable schema with custom resolvers
user_type = ObjectType("User")

@user_type.field("role")
def resolve_user_role(user, info):
    """Custom resolver for User.role to prevent enum serialization"""
    if isinstance(user, dict):
        return user.get("role", "player")
    return getattr(user, "role", "player")

schema = make_executable_schema(type_defs, query, mutation, user_type)

