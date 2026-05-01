# Backend Development Phases

This document breaks down the backend development work into manageable phases for singalong-master and singalong-node services. Each phase builds upon previous ones and can be implemented independently.

---

## Phase B1: JWT Authentication & API Key Management

**Goal**: Implement secure authentication using API keys and JWT tokens.

**Scope**: Both Master and Node services

**Deliverables**:

### Master Service
- API key validation middleware
- JWT token generation (access + refresh tokens)
- Token validation and refresh logic
- Protected endpoints that require Bearer token
- Environment variable loading for API key (hardcoded in .env)

### Node Service
- Same JWT authentication middleware
- Same token generation and refresh logic
- Same protected endpoints

**API Endpoints**:

```
POST /auth/token
Description: Exchange API key for JWT tokens
Request:
  Headers:
    X-API-Key: <api-key-from-env>
Response: 200 OK
  {
    "access_token": "<jwt-token>",
    "refresh_token": "<jwt-token>",
    "token_type": "Bearer",
    "expires_in": 3600
  }

POST /auth/refresh
Description: Refresh access token using refresh token
Request:
  Headers:
    Authorization: Bearer <refresh-token>
Response: 200 OK
  {
    "access_token": "<new-jwt-token>",
    "expires_in": 3600
  }

GET /health
Description: Service health check (public, no auth required)
Response: 200 OK
  {
    "status": "healthy",
    "service": "singalong-master" | "singalong-node",
    "timestamp": "2026-04-23T15:59:11Z"
  }
```

**Implementation Details**:

- JWT tokens use HS256 algorithm
- Secret key stored in environment variable (loaded on startup)
- Access token TTL: 1 hour (configurable)
- Refresh token TTL: 7 days (configurable)
- All protected endpoints check `Authorization: Bearer <token>` header
- Return 401 Unauthorized if token missing or invalid
- Return 403 Forbidden if token expired (except for /auth/refresh which accepts expired access tokens)

**Dependencies**: None (first authentication phase)

**Acceptance Criteria**:
- API key validation works with hardcoded .env value
- JWT tokens generated with correct claims
- Token refresh extends access
- Protected endpoints reject requests without valid Bearer token
- Health endpoint accessible without authentication
- All responses follow consistent format

---

## Phase B2: Master - Song Download Request Endpoint

**Goal**: Implement endpoint for receiving song download requests from Node.

**Scope**: Master service only

**Deliverables**:
- Song download request endpoint
- Request validation
- Draft song creation in database
- YT-DLP integration for download (basic setup)
- Response with download status

**API Endpoint**:

```
POST /api/songs/download-request
Description: Request master to download a song from YouTube
Authentication: Required (Bearer token)
Request:
  {
    "url": "https://www.youtube.com/watch?v=...",
    "metadata": {
      "title": "Song Title",
      "artist": "Artist Name",
      "duration": 180,
      "genre": "Pop",
      "year": 2020
    },
    "requested_by": "user-id-or-nickname"
  }
Response: 202 Accepted (async download)
  {
    "song_id": "uuid",
    "status": "downloading",
    "message": "Download request accepted",
    "url": "https://www.youtube.com/watch?v=..."
  }

GET /api/songs/{song_id}/status
Description: Check download progress
Authentication: Required (Bearer token)
Response: 200 OK
  {
    "song_id": "uuid",
    "status": "downloading" | "completed" | "failed",
    "progress": 0-100,
    "error": null | "error-message"
  }
```

**Implementation Details**:

- Create database table for draft/pending songs
- Validate YouTube URL format before accepting
- Validate metadata (title, artist required; duration must be > 0)
- Create song record with status="downloading"
- Trigger async download task (can use simple threading for MVP)
- YT-DLP integration: download audio/video from URL
- Store song file with unique identifier
- Update song status to "completed" when done
- Handle download errors gracefully

**Database Schema**:

```sql
CREATE TABLE songs (
  id UUID PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  artist VARCHAR(255) NOT NULL,
  duration INTEGER,
  genre VARCHAR(100),
  year INTEGER,
  url TEXT,
  file_path TEXT,
  status ENUM('draft', 'downloading', 'completed', 'failed'),
  requested_by VARCHAR(255),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE download_requests (
  id UUID PRIMARY KEY,
  song_id UUID REFERENCES songs(id),
  youtube_url TEXT NOT NULL,
  metadata JSON,
  status ENUM('pending', 'processing', 'completed', 'failed'),
  progress INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Dependencies**: Phase B1 (Authentication)

**Acceptance Criteria**:
- Endpoint accepts valid download requests
- Rejects invalid URLs or metadata
- Creates draft song in database
- Downloads file from YouTube via YT-DLP
- Reports download status
- Handles errors gracefully
- Song file stored and retrievable

---

## Phase B3: Node - User Authentication (/auth)

**Goal**: Implement endpoint for attendees to authenticate with nickname and optional password.

**Scope**: Node service only

**Deliverables**:
- User authentication endpoint
- Session creation
- User identification mechanism

**API Endpoint**:

```
POST /api/sessions/{session-id}/auth
Description: Authenticate user to join a session
Request:
  {
    "nickname": "John",
    "password": "optional-password"
  }
Response: 200 OK
  {
    "user_id": "uuid",
    "nickname": "John",
    "session_id": "session-uuid",
    "joined_at": "2026-04-23T15:59:11Z"
  }
```

**Implementation Details**:

- Create users table with nickname, optional password hash
- Generate unique user_id (UUID)
- Store user session association
- If password provided, hash with bcrypt before storage
- If password required but not provided, return 400 Bad Request
- Return user_id for use in subsequent requests

**Database Schema**:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  nickname VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE session_users (
  session_id UUID NOT NULL,
  user_id UUID NOT NULL,
  nickname VARCHAR(255),
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (session_id, user_id)
);
```

**Dependencies**: Phase B1 (Authentication)

**Acceptance Criteria**:
- User can join session with nickname
- User ID generated and returned
- Optional password support
- Session-user relationship tracked
- Multiple users can join same session
- User list can be retrieved for session

---

## Phase B4: Node - Song Search (/search)

**Goal**: Implement YouTube search functionality for finding songs.

**Scope**: Node service only

**Deliverables**:
- YouTube search endpoint using YT-DLP
- Search result formatting
- Caching of results (optional)

**API Endpoint**:

```
GET /api/search?q=<keywords>&limit=10
Description: Search YouTube for songs
Authentication: Required (Bearer token)
Query Parameters:
  - q: search keywords (required)
  - limit: number of results (default: 10, max: 50)
Response: 200 OK
  {
    "query": "bohemian rhapsody karaoke",
    "results": [
      {
        "id": "youtube-video-id",
        "title": "Bohemian Rhapsody - Karaoke Version",
        "artist": "Queen",
        "duration": 354,
        "url": "https://www.youtube.com/watch?v=...",
        "thumbnail": "https://...",
        "views": 1000000,
        "channel": "Karaoke Channel"
      },
      ...
    ],
    "count": 5
  }
```

**Implementation Details**:

- Use YT-DLP to query YouTube with search query
- Append "karaoke" or "instrumental" to query by default (configurable)
- Extract metadata: title, duration, URL, thumbnail
- Format results in consistent structure
- Limit results to requested amount
- Handle no results gracefully
- Simple caching: cache results for 1 hour per query

**Dependencies**: Phase B1 (Authentication), YT-DLP installed

**Acceptance Criteria**:
- Search returns relevant results
- Results include all metadata
- Limited to requested count
- Handles special characters in search query
- Returns empty array if no matches
- Reasonable performance (< 5 second response)

---

## Phase B5: Node - Song Identification (/identify)

**Goal**: Extract metadata from YouTube URL using YT-DLP.

**Scope**: Node service only

**Deliverables**:
- URL metadata extraction endpoint
- Error handling for invalid/unavailable videos

**API Endpoint**:

```
POST /api/songs/identify
Description: Extract song details from YouTube URL
Authentication: Required (Bearer token)
Request:
  {
    "url": "https://www.youtube.com/watch?v=..."
  }
Response: 200 OK
  {
    "id": "youtube-video-id",
    "title": "Song Title",
    "artist": "Artist Name (or channel name)",
    "duration": 180,
    "url": "https://www.youtube.com/watch?v=...",
    "thumbnail": "https://...",
    "description": "Full video description",
    "channel": "Channel Name"
  }

Response: 400 Bad Request (invalid URL)
  {
    "error": "invalid_url",
    "message": "URL is not a valid YouTube link"
  }

Response: 404 Not Found (video unavailable)
  {
    "error": "video_not_found",
    "message": "Video is not available or has been removed"
  }
```

**Implementation Details**:

- Validate YouTube URL format (various formats: short, long, mobile, etc.)
- Use YT-DLP to fetch metadata without downloading
- Extract: title, duration, channel, description, thumbnail
- Infer artist from title or channel name
- Handle errors: invalid URL, video unavailable, age-restricted, etc.
- Cache results: store identified videos with TTL

**Dependencies**: Phase B1 (Authentication), YT-DLP installed

**Acceptance Criteria**:
- Correctly identifies YouTube videos
- Extracts all required metadata
- Handles various YouTube URL formats
- Returns appropriate errors for unavailable videos
- Reasonable performance (< 5 second response)

---

## Phase B6: Node - Song Enhancement (/enhance)

**Goal**: Improve song metadata using OpenAI API.

**Scope**: Node service only

**Deliverables**:
- Song enhancement endpoint
- OpenAI integration
- Metadata validation and formatting

**API Endpoint**:

```
POST /api/songs/enhance
Description: Enhance song metadata using AI
Authentication: Required (Bearer token)
Request:
  {
    "title": "Song Title (may be incorrect)",
    "artist": "Artist Name (may be incorrect)",
    "duration": 180,
    "details": {
      "raw_title": "original youtube title",
      "channel": "channel name"
    }
  }
Response: 200 OK
  {
    "title": "Corrected Song Title",
    "artist": "Correct Artist Name",
    "duration": 180,
    "genre": "Pop",
    "year": 2020,
    "confidence": 0.95,
    "notes": "AI corrections applied: title corrected, artist confirmed"
  }

Response: 400 Bad Request
  {
    "error": "invalid_input",
    "message": "Required fields missing or invalid"
  }
```

**Implementation Details**:

- Prepare prompt for OpenAI to:
  - Correct song title if it contains typos or extra text
  - Identify correct artist name
  - Infer genre if possible
  - Infer release year if possible
  - Provide confidence score (0-1)
- Use OpenAI API (GPT-4 or GPT-3.5-turbo)
- Handle API errors gracefully
- Cache results by (title, artist) tuple
- Return enhanced metadata with confidence scores

**Prompt Template** (example):

```
You are a music metadata expert. Given the following song information, 
please provide corrected and enhanced metadata.

Raw Title: {raw_title}
Channel: {channel}
Duration: {duration} seconds

Provide your response in JSON format with:
- title: corrected song title
- artist: correct artist name
- genre: music genre (if identifiable)
- year: release year (if identifiable)
- confidence: confidence score 0-1
- notes: brief explanation of changes

Only suggest corrections if you are confident. For uncertain fields, 
return the original value.
```

**Environment Variables**:
- `OPENAI_API_KEY` - OpenAI API key
- `OPENAI_MODEL` - Model to use (default: gpt-3.5-turbo)

**Dependencies**: Phase B1 (Authentication), OpenAI API key

**Acceptance Criteria**:
- Corrects obvious typos and formatting issues
- Identifies correct artist information
- Provides confidence scores
- Handles OpenAI API errors gracefully
- Reasonable performance (< 10 second response)
- Caches results to avoid redundant API calls

---

## Phase B7: Node - Song Suggestion (/suggest)

**Goal**: Submit enhanced song details to Master for download and optionally reserve it.

**Scope**: Node service only

**Deliverables**:
- Song suggestion submission endpoint
- Master communication (HTTP request to download endpoint)
- Auto-reserve option
- Song tracking

**API Endpoint**:

```
POST /api/songs/suggest
Description: Suggest a new song for download and optional reservation
Authentication: Required (Bearer token)
Request:
  {
    "youtube_url": "https://www.youtube.com/watch?v=...",
    "metadata": {
      "title": "Song Title",
      "artist": "Artist Name",
      "duration": 180,
      "genre": "Pop",
      "year": 2020
    },
    "suggested_by": "user-id",
    "auto_reserve": true | false
  }
Response: 202 Accepted (async processing)
  {
    "suggestion_id": "uuid",
    "song_id": "uuid",
    "status": "submitted",
    "message": "Song suggestion submitted to master for download",
    "url": "https://www.youtube.com/watch?v=...",
    "auto_reserve": true
  }

GET /api/songs/{song_id}/suggestion-status
Description: Check suggestion processing status
Response: 200 OK
  {
    "song_id": "uuid",
    "status": "submitted" | "downloading" | "completed" | "failed",
    "reserved": true | false,
    "error": null | "error-message"
  }
```

**Implementation Details**:

- Store suggestion in database with status="submitted"
- Forward request to Master `/api/songs/download-request` endpoint
- Include Bearer token in request to Master
- Monitor Master status endpoint for completion
- If `auto_reserve=true`, automatically create reservation upon completion
- Handle Master unreachable errors (queue for retry)
- Broadcast completion to connected WebSocket clients via Node-WS

**Database Schema**:

```sql
CREATE TABLE song_suggestions (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL,
  song_id UUID,
  youtube_url TEXT NOT NULL,
  metadata JSON NOT NULL,
  suggested_by UUID NOT NULL,
  auto_reserve BOOLEAN DEFAULT false,
  status ENUM('submitted', 'downloading', 'completed', 'failed'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE TABLE reservations (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL,
  song_id UUID NOT NULL,
  user_id UUID NOT NULL,
  position INTEGER,
  status ENUM('pending', 'singing', 'completed'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Dependencies**: Phase B1 (Auth), Phase B2 (Master download), Phase B5 (Identify)

**Acceptance Criteria**:
- Suggestion submitted to Master successfully
- Monitors download progress
- Auto-reserve creates reservation when complete
- Returns appropriate error if Master unreachable
- Broadcasts completion via WebSocket
- Duplicate suggestions prevented (same URL, same session)

---

## Phase B8: Node - Session Management

**Goal**: Implement session creation and management endpoints.

**Scope**: Node service only

**Deliverables**:
- Session creation
- Session list
- Session details
- User management per session

**API Endpoints**:

```
POST /api/sessions
Description: Create a new karaoke session
Authentication: Required (Bearer token)
Request:
  {
    "title": "Birthday Party",
    "vibes": ["party", "upbeat"],
    "max_users": 20
  }
Response: 201 Created
  {
    "session_id": "uuid",
    "title": "Birthday Party",
    "code": "ABC123",
    "created_at": "2026-04-23T15:59:11Z",
    "created_by": "admin-user-id"
  }

GET /api/sessions/{session-id}
Description: Get session details
Response: 200 OK
  {
    "session_id": "uuid",
    "title": "Birthday Party",
    "code": "ABC123",
    "users": [
      {"user_id": "uuid", "nickname": "John", "joined_at": "..."},
      {"user_id": "uuid", "nickname": "Jane", "joined_at": "..."}
    ],
    "song_count": 150,
    "queue_length": 5
  }

GET /api/sessions/{session-id}/users
Description: List users in session
Response: 200 OK
  {
    "users": [...]
  }
```

**Database Schema**:

```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY,
  code VARCHAR(10) UNIQUE NOT NULL,
  title VARCHAR(255) NOT NULL,
  vibes TEXT,
  max_users INTEGER,
  created_by UUID NOT NULL,
  status ENUM('active', 'paused', 'ended'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP
);
```

**Dependencies**: Phase B1 (Authentication)

**Acceptance Criteria**:
- Session created with unique code
- Users can list and join sessions
- Session details retrieves user list and stats
- Session code can be used for quick access

---

## Implementation Order

**Recommended sequence** (can parallelize later phases):

1. **Phase B1** → JWT Authentication (foundation for all)
2. **Phase B2** → Master Download Endpoint (core feature)
3. **Phase B3** → Node User Auth (enables sessions)
4. **Phase B8** → Node Session Management (structure for features)
5. **Phase B4** → Node Search (independent feature)
6. **Phase B5** → Node Identify (independent feature)
7. **Phase B6** → Node Enhancement (builds on identify)
8. **Phase B7** → Node Suggest (integrates all previous)

## Dependencies Summary

```
B1 (Auth)
├── B2 (Master download)
├── B3 (Node user auth)
├── B4 (Node search)
├── B5 (Node identify)
└── B8 (Session mgmt)
    └── B6 (Enhance)
        └── B5 (Identify)
            └── B7 (Suggest)
                └── B2 (Master download)
```

---

## Technology Stack (Backend)

- **Framework**: FastAPI (Python)
- **Authentication**: PyJWT for JWT tokens
- **Password Hashing**: bcrypt
- **Database**: PostgreSQL (or SQLite for MVP)
- **YouTube Integration**: yt-dlp
- **AI Integration**: OpenAI Python client
- **HTTP Client**: httpx (for async requests)
- **Task Queue**: Celery or simple threading (for async downloads)

---

## Status

This roadmap is ready for phase-by-phase implementation. Each phase can be worked on independently after its dependencies are complete.
