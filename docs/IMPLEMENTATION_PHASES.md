# Singalong Implementation Phases

## Phase Approach

The implementation is broken into phases that follow a dependency chain: **Infrastructure → Core APIs → Backend Features → Frontend Features → Integration & Polish**

Each phase builds on previous ones and delivers measurable functionality.

---

## Phase 1: Project Setup & Infrastructure

**Goal**: Establish development environment and baseline project structure.

**Deliverables**:
- Docker Compose configuration for all 4 services
- Development environment with hot reload for all services
- Health check endpoints for all services
- Basic API documentation structure
- CI/CD pipeline foundations (optional)

**Dependencies**: None (first phase)

**Acceptance Criteria**:
- All 4 services can start with `docker-compose up`
- Each service responds to `/health` endpoint
- Services can communicate across the docker network
- Development environment supports hot reload for both Python and React

---

## Phase 2: Master Server - Song Management Foundation

**Goal**: Build the Master server's core song management and storage capabilities.

**Deliverables**:
- Database schema for songs, metadata, and draft songs
- Song CRUD endpoints (Create, Read, Update, Delete)
- Song listing/pagination endpoints
- Draft song workflow (create → download → finalize)
- YT-DLP integration for metadata extraction
- Song file storage mechanism (filesystem or cloud)

**Dependencies**: Phase 1

**Acceptance Criteria**:
- Can create, read, list, and delete songs
- Can query songs with pagination and filtering
- Draft songs can be created and promoted to published
- YT-DLP successfully extracts video metadata (title, duration, etc.)
- Songs can be stored and retrieved from disk

---

## Phase 3: Node Server - Core Gateway & Session Management

**Goal**: Implement Node as the middleware between frontends and Master, with session management.

**Deliverables**:
- Node → Master communication layer (HTTP client with retry logic)
- Session creation and management endpoints
- User/attendee connection tracking
- Song reservation/queue management
- Songbook listing endpoint (proxied from Master)
- Health endpoint with Master connectivity status
- Local song caching mechanism

**Dependencies**: Phase 2

**Acceptance Criteria**:
- Node can create and manage sessions
- Node can track connected users per session
- Users can be added to a session
- Node can fetch songbook from Master and cache locally
- Reservations are stored per session with ordering capability
- Admin can reorder the reservation queue

---

## Phase 4: Controller (Attendee) - Frontend MVP

**Goal**: Build the attendee-facing UI with core functionality.

**Deliverables**:
- Session join flow (enter session code, set nickname)
- Songbook browsing and search
- Song reservation interface
- Reserved songs list view
- User profile/settings (nickname)
- Real-time updates (WebSocket or polling) for queue changes

**Dependencies**: Phase 3

**Acceptance Criteria**:
- Can join an active session
- Can view available songbook
- Can reserve a song
- Can see personal reservations
- Sees updated songbook when changes occur
- UI is responsive and mobile-friendly

---

## Phase 5: Admin (Admin) - Frontend MVP

**Goal**: Build the admin-facing UI for session and user management.

**Deliverables**:
- Session creation form (title, vibes, settings)
- User/connection management dashboard
- Queue reordering interface (drag-and-drop or manual)
- All Controller features available to admin
- Session status and health monitoring
- Manual song reservation on behalf of guests

**Dependencies**: Phase 4

**Acceptance Criteria**:
- Can create a new session with title and metadata
- Can view connected users
- Can manually reserve songs for guests
- Can reorder the song queue
- Can access all attendee features
- Sees real-time updates to the session

---

## Phase 6: Song Discovery - YouTube Search Integration

**Goal**: Implement the ability to search for and suggest new songs from YouTube.

**Deliverables**:
- Built-in YouTube search endpoint on Node (uses YT-DLP)
- URL validation and metadata extraction (Node → YT-DLP)
- Metadata enhancement UI in Controller/Admin
- Song suggestion submission flow (Controller/Admin → Node → Master)
- Draft song workflow notification system
- Download progress tracking (optional)

**Dependencies**: Phase 3, Phase 5

**Acceptance Criteria**:
- Can search YouTube from Controller
- Can paste a YouTube URL and validate it
- Can view and edit song metadata before submission
- Can submit new song suggestion to Master via Node
- Master receives request and starts download
- User is notified when download completes
- Song becomes available in songbook after completion

---

## Phase 7: Real-Time Features - WebSocket & Notifications

**Goal**: Implement real-time sync and notifications for better UX.

**Deliverables**:
- WebSocket connection setup between Node and frontends
- Real-time queue updates (when songs are added/reordered)
- Real-time user join/leave notifications
- Real-time download progress notifications
- Fallback to polling for clients that don't support WebSocket
- Event broadcasting system in Node

**Dependencies**: Phase 4, Phase 5, Phase 6

**Acceptance Criteria**:
- Multiple users see queue updates instantly
- Queue reorders are reflected immediately on all clients
- Users see notifications when someone joins/leaves
- Download progress is streamed to the user who suggested it
- System gracefully degrades if WebSocket unavailable

---

## Phase 8: Playback Control - Session Playback Integration

**Goal**: Implement song playback control and session flow management.

**Deliverables**:
- Playback state tracking in Node (current song, elapsed time, etc.)
- Admin playback controls (play, pause, skip, next)
- Player UI in Controller/Admin (minimal - just status display)
- Queue progression logic (auto-move to next song)
- Song history tracking per session
- Playback status broadcast to all connected clients

**Dependencies**: Phase 7

**Acceptance Criteria**:
- Admin can play/pause current song
- Admin can skip to next reserved song
- Queue progresses automatically
- All attendees see current playback status
- Can view session song history

---

## Phase 9: Offline Mode & Resilience

**Goal**: Enable sessions to continue even without Master connectivity.

**Deliverables**:
- Graceful degradation when Master is unavailable
- Offline queue persistence in Node
- Offline song search limitations (cached results only)
- Sync queue when Master comes back online
- Connection retry logic with exponential backoff
- Offline mode indicators in UI

**Dependencies**: Phase 3, Phase 6

**Acceptance Criteria**:
- Node continues to serve existing sessions when Master is down
- Can still reserve songs from cached songbook
- New song suggestions are queued and synced when Master returns
- Connection status is visible in Admin UI

---

## Phase 10: Quality & Hardening

**Goal**: Polish, test, and optimize the system.

**Deliverables**:
- Unit tests for critical paths (>80% coverage)
- Integration tests for Node ↔ Master communication
- E2E tests for core workflows (join → reserve → playback)
- Performance optimization and load testing
- Error handling refinement
- Documentation and deployment guides
- Security review and fixes

**Dependencies**: All previous phases

**Acceptance Criteria**:
- All critical paths have tests
- Services handle errors gracefully
- System documentation is complete
- Can handle concurrent users smoothly
- Security vulnerabilities addressed

---

## Dependency Graph

```
Phase 1 (Setup)
    ↓
Phase 2 (Master Foundation)
    ↓
Phase 3 (Node Core)
    ├→ Phase 4 (Controller MVP)
    │   ↓
    └→ Phase 5 (Admin MVP)
        ↓
Phase 6 (Song Discovery) [depends on 3, 5]
    ↓
Phase 7 (Real-Time) [depends on 4, 5, 6]
    ↓
Phase 8 (Playback) [depends on 7]
    ↓
Phase 9 (Offline) [depends on 3, 6]
    ↓
Phase 10 (Quality)
```

---

## Phase Grouping for Milestones

**Milestone 1 - MVP (Sessions & Reservations)**:
- Phases 1-5: Basic session setup, songbook browsing, reservations, admin controls

**Milestone 2 - Song Discovery**:
- Phase 6: YouTube search, song suggestions, downloads

**Milestone 3 - Real-Time & Playback**:
- Phases 7-8: WebSocket, live updates, playback control

**Milestone 4 - Resilience & Polish**:
- Phases 9-10: Offline support, quality, hardening

---

## Design Decisions (Assumptions for MVP)

1. **Authentication**: Not required for MVP. Sessions are join-code based. Admin setup is local/trusted.
2. **Metadata Enhancement**: User enhancements are auto-saved as-is (no approval workflow). Source is attributed to user.
3. **Download Queue**: Master processes downloads in FIFO order as requests arrive.
4. **Session Persistence**: Session data is stored for archives (who sang, when, metadata). Queryable via Admin after session ends.
5. **Offline Mode**: Node caches full songbook + recently played songs. New downloads are queued for sync when online.
6. **Song Storage**: Use local filesystem for MVP. Upgrade to cloud storage (S3, etc.) in future.
7. **Real-Time**: WebSocket preferred, with polling fallback.
8. **Playback**: Admin controls only. Actual audio playback is out of scope for MVP (UI tracks state only).

---

## Status: Complete

This plan is ready for phase breakdown and sprint planning. Each phase can be implemented and tested independently before moving to the next.
