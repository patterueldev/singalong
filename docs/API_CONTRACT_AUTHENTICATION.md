# Singalong API Authentication Contract

## Overview

This document defines the authentication and authorization mechanism for inter-service communication in Singalong, specifically the contract between **Node** and **Master** services.

**Principle**: All backend services communicate via REST APIs with JWT-based authentication. Frontend applications authenticate through the Node service, which then communicates with Master on their behalf.

---

## 1. Authentication Flow

### 1.1 Master-to-Node Communication

When Node needs to communicate with Master (fetching songs, downloading, etc.):

```
┌──────────────┐                                    ┌──────────────┐
│ Node Service │                                    │Master Service│
└──────┬───────┘                                    └──────┬───────┘
       │                                                   │
       │─ 1. POST /api/auth/exchange                      │
       │     (payload: api_key)                           │
       │──────────────────────────────────────────────────>│
       │                                                   │
       │     2. Validate api_key from .env                │
       │     3. Generate JWT tokens                       │
       │                                                   │
       │<──────────────────────────────────────────────────│
       │     (response: access_token, refresh_token)      │
       │                                                   │
       │ 4. Store tokens in memory/cache                  │
       │ (with TTL matching access_token expiry)          │
       │                                                   │
       │─ 5. GET /api/songs                               │
       │     (header: Authorization: Bearer <token>)      │
       │──────────────────────────────────────────────────>│
       │                                                   │
       │     6. Validate JWT signature and expiry         │
       │     7. Process request                           │
       │                                                   │
       │<──────────────────────────────────────────────────│
       │     (response: songs array + metadata)           │
```

---

## 2. API Key Configuration

### Master Service (.env)

```env
# Master API Key - Used by Node to authenticate
# Generated at startup and never changes during service lifetime
MASTER_API_KEY=your-secret-key-here-min-32-chars
SERVICE_NAME=singalong-master
DEBUG=false
```

**Requirements**:
- Minimum 32 characters (use cryptographically secure random)
- Loaded once at application startup
- Never logged or exposed in error messages
- Environment-specific (different key per environment: dev, staging, prod)

### Node Service (.env)

```env
# Master Service Configuration
MASTER_URL=http://singalong-master:5001
MASTER_API_KEY=your-secret-key-here-min-32-chars  # Must match Master's key
SERVICE_NAME=singalong-node
DEBUG=false
```

---

## 3. JWT Token Specification

### Token Types

#### 3.1 Access Token
- **TTL**: 1 hour (3600 seconds)
- **Scope**: Authorization for API requests
- **Use**: Included in `Authorization: Bearer <token>` header
- **Refresh**: Use refresh token before expiry

#### 3.2 Refresh Token
- **TTL**: 7 days (604800 seconds)
- **Scope**: Generate new access token
- **Use**: POST to `/api/auth/refresh`
- **Refresh**: Generate new refresh token simultaneously

### Token Payload (Claims)

```json
{
  "sub": "singalong-node",           // Subject (service identifier)
  "service_name": "singalong-node",  // Redundant for clarity
  "iat": 1706835600,                 // Issued at (timestamp)
  "exp": 1706839200,                 // Expiration time
  "token_type": "access"             // For token type differentiation
}
```

---

## 4. Authentication Endpoints

### 4.1 Exchange API Key for Tokens

**Endpoint**: `POST /api/auth/exchange`

**Request**:
```json
{
  "api_key": "your-secret-key-here-min-32-chars"
}
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800
}
```

**Errors**:
```json
{
  "status": "error",
  "code": "INVALID_API_KEY",
  "message": "API key is invalid or expired"
}
```

**Implementation Notes**:
- No rate limiting at this point (assume trusted network)
- Both tokens generated simultaneously
- Can be called multiple times; each call invalidates previous tokens
- Node should cache tokens in memory with automatic refresh before expiry

---

### 4.2 Refresh Access Token

**Endpoint**: `POST /api/auth/refresh`

**Request**:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800
}
```

**Errors**:
```json
{
  "status": "error",
  "code": "INVALID_REFRESH_TOKEN",
  "message": "Refresh token is invalid or expired"
}
```

**Implementation Notes**:
- Both tokens can be refreshed simultaneously
- Old tokens should be invalidated (optional: maintain blacklist if needed)
- Return new tokens immediately

---

### 4.3 Validate Token (Health Check)

**Endpoint**: `GET /api/auth/validate`

**Headers**: 
```
Authorization: Bearer <access_token>
```

**Response** (200 OK):
```json
{
  "status": "valid",
  "sub": "singalong-node",
  "iat": 1706835600,
  "exp": 1706839200,
  "expires_in": 3599
}
```

**Errors** (401 Unauthorized):
```json
{
  "status": "error",
  "code": "INVALID_TOKEN",
  "message": "Token is invalid or expired"
}
```

---

## 5. Authorization Middleware

All authenticated endpoints require the `Authorization: Bearer <token>` header.

### 5.1 Header Format

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 5.2 Processing Flow

```
1. Extract token from Authorization header
2. Verify token signature using SECRET_KEY
3. Check token expiration (exp claim)
4. Check token type (access vs refresh)
5. Extract service identity (sub claim)
6. Allow request to proceed
7. If validation fails, return 401 Unauthorized
```

### 5.3 Error Responses

**401 Unauthorized** (Missing or Invalid Token):
```json
{
  "status": "error",
  "code": "MISSING_AUTHORIZATION",
  "message": "Authorization header is missing or invalid"
}
```

**401 Unauthorized** (Expired Token):
```json
{
  "status": "error",
  "code": "TOKEN_EXPIRED",
  "message": "Token has expired. Please refresh.",
  "should_refresh": true
}
```

**403 Forbidden** (Insufficient Scope):
```json
{
  "status": "error",
  "code": "INSUFFICIENT_SCOPE",
  "message": "Your service does not have permission for this operation"
}
```

---

## 6. Frontend Authentication (Through Node)

Frontend applications (Admin, Controller) authenticate through Node, not directly with Master.

### 6.1 Controller → Node Authentication

**Flow**:
1. Controller connects to Node and sends user nickname
2. Node validates and creates user session
3. Node returns session token for Controller
4. Controller includes session token in all subsequent requests
5. Node handles Master communication transparently

**Endpoint**: `POST /api/auth` (Node-specific, not used for Master)

```json
{
  "nickname": "Alice",
  "password": "optional-password"  // Optional, for sessions with access control
}
```

**Response**:
```json
{
  "session_token": "user-session-jwt",
  "user_id": "user-uuid",
  "session_id": "session-uuid"
}
```

---

## 7. Implementation Checklist

### Master Service (singalong-master)

- [ ] Load `MASTER_API_KEY` from `.env` at startup
- [ ] Create JWT encoding/decoding service using PyJWT
- [ ] Implement `POST /api/auth/exchange` endpoint
- [ ] Implement `POST /api/auth/refresh` endpoint
- [ ] Implement `GET /api/auth/validate` endpoint
- [ ] Create authorization middleware
  - [ ] Extract Bearer token from header
  - [ ] Validate JWT signature
  - [ ] Check token expiration
  - [ ] Return 401 on failure
  - [ ] Attach service identity to request context
- [ ] Add token to all authenticated endpoint responses
- [ ] Create error response models
- [ ] Add logging for authentication events (without exposing keys)
- [ ] Create tests for all auth scenarios

### Node Service (singalong-node)

- [ ] Load `MASTER_API_KEY` from `.env`
- [ ] Load `MASTER_URL` from `.env`
- [ ] Create HTTP client for Master communication
- [ ] Implement token exchange on startup
  - [ ] Exchange API key for tokens
  - [ ] Cache access token in memory
  - [ ] Cache refresh token in memory
- [ ] Implement automatic token refresh
  - [ ] Check token expiry before making requests
  - [ ] Refresh if expiry < 5 minutes away
  - [ ] Handle refresh failures (retry with exponential backoff)
- [ ] Add Bearer token to all Master requests
- [ ] Implement circuit breaker for Master communication
  - [ ] Track consecutive failures
  - [ ] Fall back to cached data after N failures
  - [ ] Restore connection after timeout
- [ ] Create tests for token management
- [ ] Create tests for Master communication

---

## 8. Security Considerations

### 8.1 API Key Management

- **Storage**: Environment variables only (never in code)
- **Rotation**: Requires service restart (for now)
- **Logging**: Never log full API key; use truncated versions like `***abc123`
- **Transport**: Always use HTTPS in production
- **Access**: Restrict access to `.env` files in code repositories

### 8.2 Token Management

- **Signing**: Use HS256 (HMAC with SHA-256) for symmetric signing
- **Secret**: Use `MASTER_API_KEY` as the signing secret
- **Storage**: Store tokens in memory only (Node), never in database
- **Expiration**: Always check `exp` claim; never trust client timestamps

### 8.3 Network Communication

- **HTTPS**: Required in production
- **Verification**: Always verify token signature before processing
- **Rate Limiting**: Consider implementing for `/api/auth/exchange` (future enhancement)
- **CORS**: Frontend apps should not call Master directly (only through Node)

---

## 9. Examples

### 9.1 Node Startup - Token Exchange

```python
# On Node service startup
async def startup():
    api_key = os.getenv("MASTER_API_KEY")
    master_url = os.getenv("MASTER_URL")
    
    response = await http_client.post(
        f"{master_url}/api/auth/exchange",
        json={"api_key": api_key}
    )
    
    tokens = response.json()
    cache.set("access_token", tokens["access_token"], ttl=tokens["expires_in"])
    cache.set("refresh_token", tokens["refresh_token"], ttl=tokens["refresh_expires_in"])
```

### 9.2 Node Making Authenticated Request

```python
# Before calling Master endpoint
async def get_songs():
    token = cache.get("access_token")
    
    # Check if expiry is approaching (< 5 minutes)
    if token_expires_in(token) < 300:
        token = await refresh_access_token()
    
    response = await http_client.get(
        f"{master_url}/api/songs",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    return response.json()
```

### 9.3 Master Authorization Middleware

```python
from fastapi import HTTPException, Depends, Header

async def verify_bearer_token(authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    
    try:
        scheme, token = authorization.split(" ")
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authorization scheme")
        
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Usage in endpoint
@app.get("/api/songs")
async def list_songs(auth: dict = Depends(verify_bearer_token)):
    # auth now contains verified token payload
    return {"songs": [...]}
```

---

## 10. Future Enhancements

- [ ] Implement rate limiting on token exchange endpoint
- [ ] Add token blacklist for revocation
- [ ] Implement key rotation strategy
- [ ] Add service-to-service mutual TLS (mTLS)
- [ ] Add audit logging for all auth events
- [ ] Implement OAuth2 for user-level auth (future phases)

---

## Document Version

- **Created**: 2026-04
- **Version**: 1.0.0
- **Status**: Ready for implementation
