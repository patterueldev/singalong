"""Middleware for GraphQL authentication"""

import jwt
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from app.services.auth_service import AuthService
from app.main import settings


class GraphQLAuthMiddleware(BaseHTTPMiddleware):
    """Middleware to validate Bearer token for GraphQL endpoint"""

    async def dispatch(self, request: Request, call_next):
        """Validate Bearer token for GraphQL requests"""
        # Only check auth for GraphQL endpoint
        if request.url.path == "/graphql":
            auth_header = request.headers.get("Authorization", "")
            if not auth_header.startswith("Bearer "):
                raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

            token = auth_header.split(" ", 1)[1]
            auth_service = AuthService(settings.master_api_key)

            try:
                auth_service.validate_token(token)
            except jwt.ExpiredSignatureError:
                raise HTTPException(status_code=401, detail="Token expired")
            except jwt.InvalidTokenError:
                raise HTTPException(status_code=401, detail="Invalid token")

        return await call_next(request)
