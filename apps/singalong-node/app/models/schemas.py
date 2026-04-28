"""Pydantic schemas for authentication"""

from pydantic import BaseModel, Field


class AuthControllerRequest(BaseModel):
    """Request schema for controller authentication"""
    nickname: str = Field(..., min_length=1, max_length=255, description="Controller nickname")
    session_id: str = Field(..., min_length=4, max_length=4, description="4-digit session ID")


class AuthAdminRequest(BaseModel):
    """Request schema for admin authentication"""
    username: str = Field(..., min_length=1, max_length=255, description="Admin username")
    password: str = Field(..., min_length=1, description="Admin password")


class AuthPlayerRequest(BaseModel):
    """Request schema for player authentication"""
    session_id: str = Field(..., min_length=4, max_length=4, description="4-digit session ID")


class RefreshTokenRequest(BaseModel):
    """Request schema for token refresh"""
    refresh_token: str = Field(..., description="Refresh token")


class TokenResponse(BaseModel):
    """Response schema for token endpoints"""
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Access token expiration in seconds")
    refresh_expires_in: int = Field(..., description="Refresh token expiration in seconds")
    role: str = Field(..., description="User role")

