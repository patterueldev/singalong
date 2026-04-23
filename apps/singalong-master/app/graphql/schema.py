"""GraphQL schema definition for user authentication"""

from ariadne import graphql_sync, make_executable_schema, MutationType
from app.services.user_auth_service import UserAuthService
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

    type Query {
        hello: String!
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
    }
"""

# Mutation resolvers
mutation = MutationType()


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


# Build executable schema
schema = make_executable_schema(type_defs, mutation)

