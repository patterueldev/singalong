"""GraphQL schema definition for user authentication and song operations"""

from ariadne import graphql_sync, make_executable_schema, MutationType, QueryType
from app.services.user_auth_service import UserAuthService
from app.services.yt_dlp_service import YTDLPService, YTDLPError
from app.database import SessionLocal

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
    }

    type Query {
        hello: String!
        identifySong(url: String!): SongMetadata!
        downloadStatus(songId: String!): DownloadResponse!
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
            url: String!
            title: String!
            artist: String
            duration: Int
            language: String
            enhancedMetadata: String
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
        }

    except ValueError as e:
        raise ValueError(str(e))
    except Exception as e:
        raise ValueError(f"Failed to get download status: {str(e)}")
    finally:
        db.close()


@mutation.field("authenticateController")
def resolve_authenticate_controller(obj, info, nickname, sessionId, nodeId):
    """Authenticate controller user"""
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
                "role": user.role.value,
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
                "role": user.role.value,
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
                "role": user.role.value,
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
    url: str,
    title: str,
    artist: str = None,
    duration: int = None,
    language: str = None,
    enhancedMetadata: str = None,
    requestedByNodeId: str = "unknown",
):
    """Request a song download from Master"""
    db = SessionLocal()
    try:
        from app.services.download_service import DownloadService

        download_service = DownloadService(db)
        draft = download_service.request_download(
            url=url,
            title=title,
            artist=artist,
            duration=duration,
            language=language,
            enhanced_metadata=enhancedMetadata,
            requested_by_node_id=requestedByNodeId,
        )

        return {
            "songId": str(draft.id),
            "status": draft.status,
            "progress": int(draft.download_progress),
            "message": "Download started",
        }

    except ValueError as e:
        raise ValueError(str(e))
    except Exception as e:
        raise ValueError(f"Failed to request download: {str(e)}")
    finally:
        db.close()


# Build executable schema
schema = make_executable_schema(type_defs, query, mutation)

