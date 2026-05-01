"""Middleware for GraphQL authentication"""

import json
import jwt
from fastapi import Request
from fastapi.responses import JSONResponse
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
                return JSONResponse(
                    status_code=401,
                    content={"error": "Unauthorized", "message": "Missing or invalid Authorization header"}
                )

            token = auth_header.split(" ", 1)[1]
            auth_service = AuthService(settings.master_api_key)

            try:
                auth_service.validate_token(token)
            except jwt.ExpiredSignatureError:
                return JSONResponse(
                    status_code=401,
                    content={"error": "Unauthorized", "message": "Token expired"}
                )
            except jwt.InvalidTokenError:
                return JSONResponse(
                    status_code=401,
                    content={"error": "Unauthorized", "message": "Invalid token"}
                )

        return await call_next(request)
