# Singalong Node - Authentication Implementation Guide

This document describes the role-based authentication system implemented for the Singalong Node service.

## Overview

The Node service provides three authentication endpoints supporting three distinct roles:

1. **Controller (Attendee)** - No password required, unique nickname per session
2. **Admin (Manager)** - Username + password authentication
3. **Player (Playback Device)** - First player locks out others, prevents concurrent playback

## Authentication Flow

### Controller Authentication
```
POST /api/auth/controller
{
  "nickname": "User123"
}

Response (201):
{
  "access_token": "eyJ0eX...",
  "refresh_token": "eyJ0eX...",
  "role": "controller",
  "expires_in": 10800,
  "refresh_expires_in": 604800,
  "token_type": "bearer"
}
```

**Error Cases:**
- 409 Conflict: Nickname already taken
- 422 Unprocessable Entity: Invalid request format

### Admin Authentication
```
POST /api/auth/admin
{
  "username": "admin",
  "password": "secret123"
}

Response (201):
{
  "access_token": "eyJ0eX...",
  "refresh_token": "eyJ0eX...",
  "role": "admin",
  "expires_in": 10800,
  "refresh_expires_in": 604800,
  "token_type": "bearer"
}
```

**Error Cases:**
- 401 Unauthorized: Invalid username or password
- 422 Unprocessable Entity: Invalid request format

### Player Authentication
```
POST /api/auth/player
{
  "username": "player1",
  "password": "devicepass123"
}

Response (201):
{
  "access_token": "eyJ0eX...",
  "refresh_token": "eyJ0eX...",
  "role": "player",
  "expires_in": 10800,
  "refresh_expires_in": 604800,
  "token_type": "bearer"
}
```

**Error Cases:**
- 401 Unauthorized: Invalid username or password
- 409 Conflict: Another player already connected
- 422 Unprocessable Entity: Invalid request format

### Token Refresh
```
POST /api/auth/refresh
{
  "refresh_token": "eyJ0eX..."
}

Response (200):
{
  "access_token": "eyJ0eX...",
  "refresh_token": "eyJ0eX...",
  "role": "controller",
  "expires_in": 10800,
  "refresh_expires_in": 604800,
  "token_type": "bearer"
}
```

**Error Cases:**
- 401 Unauthorized: Refresh token expired or invalid
- 422 Unprocessable Entity: Invalid request format

## Using Tokens

All protected endpoints require the token in the Authorization header:

```bash
curl -H "Authorization: Bearer eyJ0eX..." http://localhost:5002/api/protected
```

## Token Claims

All JWT tokens include these claims:

```json
{
  "sub": "user-uuid",          // User ID
  "role": "controller",         // User role (controller, admin, player)
  "service_name": "singalong-node",
  "iat": 1234567890,           // Issued at
  "exp": 1234581690,           // Expires at
  "token_type": "access"       // Type (access or refresh)
}
```

## Token Expiration

- **Access Tokens**: 3 hours (10,800 seconds)
- **Refresh Tokens**: 7 days (604,800 seconds)

Configure via environment variables:
```
JWT_ACCESS_TOKEN_EXPIRE_SECONDS=10800
JWT_REFRESH_TOKEN_EXPIRE_SECONDS=604800
```

## Database Models

### User
Tracks all authenticated users with their assigned role.
- `id`: UUID primary key
- `nickname_or_username`: Unique identifier
- `role`: ENUM (controller, admin, player)
- `created_at`: Timestamp

### AdminCredentials
Stores admin username and bcrypt-hashed password.
- `id`: UUID primary key
- `username`: Unique identifier
- `password_hash`: bcrypt hash (12 rounds)
- `created_at`: Timestamp

### PlayerCredentials
Stores player username and bcrypt-hashed password.
- `id`: UUID primary key
- `username`: Unique identifier
- `password_hash`: bcrypt hash (12 rounds)
- `created_at`: Timestamp

### PlayerConnection
Tracks active player sessions and heartbeats.
- `id`: UUID primary key
- `player_id`: Foreign key to User
- `connected_at`: Connection timestamp
- `last_heartbeat`: Last heartbeat timestamp (for WebSocket monitoring)

## Configuration

Required environment variables in `.env`:

```
# JWT Configuration
JWT_SECRET_KEY=your-secret-key-min-32-chars
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_SECONDS=10800
JWT_REFRESH_TOKEN_EXPIRE_SECONDS=604800

# Database
DATABASE_URL=sqlite:///./singalong_node.db

# Master Service
MASTER_URL=http://localhost:5001
```

## Implementation Details

### Password Hashing
- Algorithm: bcrypt
- Rounds: 12
- Never stored in plaintext
- Verified at authentication time

### JWT Signing
- Algorithm: HS256 (HMAC with SHA-256)
- Secret: `JWT_SECRET_KEY` environment variable
- Used for both access and refresh tokens

### Player Lock Mechanism
When a player authenticates:
1. Check if any PlayerConnection record exists
2. If yes, reject with 409 Conflict error
3. If no, create PlayerConnection record
4. Player remains connected until:
   - Token expires (7 days for refresh token)
   - Manual disconnect/logout
   - Heartbeat timeout (future feature)

### Nickname Uniqueness
Controller nicknames are enforced unique at the database level:
- Unique constraint on `User.nickname_or_username` where `role = CONTROLLER`
- Duplicate attempt returns 409 Conflict

## Testing

Run tests with:
```bash
poetry run pytest app/tests/ -v
```

Current test coverage:
- 44 tests
- 100% authentication logic coverage
- Password hashing, validation, token generation
- All endpoint behaviors and error cases

## Security Considerations

✓ Passwords hashed with bcrypt (12 rounds)
✓ JWT tokens signed with strong secret
✓ Token expiration enforced
✓ Service name validation in tokens
✓ Role-based access control ready via middleware
✓ Bearer token validation middleware included

⚠️ Production checklist:
- [ ] Change JWT_SECRET_KEY to strong random value (32+ chars)
- [ ] Use HTTPS in production
- [ ] Store JWT_SECRET_KEY in secure vault
- [ ] Set secure cookie flags for any cookies
- [ ] Implement rate limiting for auth endpoints
- [ ] Add CORS configuration if needed
- [ ] Monitor for suspicious authentication patterns
- [ ] Rotate JWT keys periodically
- [ ] Use PostgreSQL instead of SQLite for production

## Middleware Usage

### Validate Bearer Token
```python
from app.middleware.auth import verify_bearer_token
from fastapi import Depends

@app.get("/protected")
async def protected_endpoint(token_payload: dict = Depends(verify_bearer_token)):
    return {"user_id": token_payload["sub"]}
```

### Require Specific Role
```python
from app.middleware.auth import require_role

@app.post("/admin-only")
@require_role("admin")
async def admin_only(token_payload: dict = Depends(verify_bearer_token)):
    return {"message": "Admin endpoint"}
```

## Next Steps

Recommended additions for Phase B3b:
- [ ] Admin credential management endpoints
- [ ] Admin endpoints for user management
- [ ] Logout/token revocation endpoint
- [ ] Player heartbeat WebSocket tracking
- [ ] Rate limiting on auth endpoints
- [ ] Email verification for admins
- [ ] Password reset flow
- [ ] Session audit logging
