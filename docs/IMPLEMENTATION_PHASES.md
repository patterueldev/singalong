# Singalong Implementation Phases

## Phase Approach

The implementation is broken into phases that follow a dependency chain: **Infrastructure → Core APIs → Backend Features → Frontend Features → Integration & Polish**

Each phase builds on previous ones and delivers measurable functionality.

---

## Service Architecture

The Singalong system consists of 6 services:

**Backend Services** (REST + WebSocket):
1. **singalong-master** (REST) - Central database, song storage, YouTube downloads via YT-DLP
2. **master-ws** (WebSocket) - Real-time notifications for download progress, draft promotions
3. **singalong-node** (REST) - Session management, middleware, song caching, YT-DLP searches
4. **node-ws** (WebSocket) - Real-time updates to frontends (queue changes, user events, downloads)

**Frontend Services** (REST + WebSocket Client):
5. **singalong-controller** (React) - Attendee UI, connects to Node REST + Node-WS
6. **singalong-admin** (React) - Admin UI, connects to Node REST + Node-WS

**Communication Flow**:
```
Master-WS ←→ (Master WebSocket events)
   ↑
   │ (REST API)
   │
Master Server
   ↑
   │ (REST API)
   │
Node Server ←→ Node-WS (WebSocket broadcasts)
   ↑                 ↑
   │ (REST/WS)       │ (WebSocket)
   │                 │
Controller ←────────┘
Admin ←─────────────┘
```

---

**Goal**: Establish development environment and baseline project structure for all 6 services.

**Deliverables**:
- Docker Compose configuration for all 6 services (Master, Master-WS, Node, Node-WS, Controller, Admin)
- Development environment with hot reload for all services
- Health check endpoints for all services
- Basic API documentation structure
- Service-to-service communication network setup
- CI/CD pipeline foundations (optional)

**Dependencies**: None (first phase)

**Acceptance Criteria**:
- All 6 services can start with `docker-compose up`
- Each service responds to `/health` endpoint
- Services can communicate across the docker network
- WebSocket services can accept connections from their respective client services
- Development environment supports hot reload for both Python and React

---

## Phase 2: Master Server - Song Management Foundation

**Goal**: Build the Master server's core song management, storage, and YouTube download capabilities.

**Deliverables**:
- Database schema for songs, metadata, and draft songs
- Song CRUD endpoints (Create, Read, Update, Delete)
- Song listing/pagination endpoints
- Draft song workflow (create → download via YT-DLP → finalize)
- YT-DLP integration for downloading videos from YouTube
- Song file storage mechanism (filesystem or cloud)
- Basic Master-WS WebSocket setup for future notifications

**Dependencies**: Phase 1

**Acceptance Criteria**:
- Can create, read, list, and delete songs
- Can query songs with pagination and filtering
- Draft songs can be created and promoted to published
- YT-DLP successfully downloads videos from YouTube
- Downloaded files are stored and retrievable from disk
- Master-WS service can accept WebSocket connections

---

## Phase 3: Node Server - Core Gateway & Session Management

**Goal**: Implement Node as the middleware between frontends and Master, with session management. Setup Node-WS for real-time communication.

**Deliverables**:
- Node → Master communication layer (HTTP client with retry logic)
- Session creation and management endpoints
- User/attendee connection tracking
- Song reservation/queue management
- Songbook listing endpoint (proxied from Master)
- Health endpoint with Master connectivity status
- Local song caching mechanism
- Node-WS WebSocket service for frontend real-time updates
- Connection between Node and Master-WS for download notifications

**Dependencies**: Phase 2

**Acceptance Criteria**:
- Node can create and manage sessions
- Node can track connected users per session
- Users can be added to a session
- Node can fetch songbook from Master and cache locally
- Reservations are stored per session with ordering capability
- Admin can reorder the reservation queue
- Node-WS can accept WebSocket connections from frontends
- Node listens to Master-WS for download events

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

## Phase 7: Real-Time Features - WebSocket Integration

**Goal**: Implement real-time sync and notifications across Master-WS, Node-WS, and frontends.

**Deliverables**:
- Master-WS download progress streaming to Node-WS
- Node-WS broadcasting of download completion to frontends
- Real-time queue updates (when songs are added/reordered)
- Real-time user join/leave notifications
- Real-time download progress notifications
- Fallback to polling for clients that don't support WebSocket
- Event broadcasting system across Master-WS → Node-WS → Frontends

**Dependencies**: Phase 4, Phase 5, Phase 6

**Acceptance Criteria**:
- Multiple users see queue updates instantly via Node-WS
- Queue reorders are reflected immediately on all clients
- Users see notifications when someone joins/leaves
- Download progress is streamed through Master-WS → Node-WS → Frontends
- System gracefully degrades if WebSocket unavailable
- Connection resilience and reconnection logic works

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
3. **Download Queue**: Master processes downloads in FIFO order as requests arrive via YT-DLP.
4. **Session Persistence**: Session data is stored for archives (who sang, when, metadata). Queryable via Admin after session ends.
5. **Offline Mode**: Node caches full songbook + recently played songs. New downloads are queued for sync when online.
6. **Song Storage**: Use local filesystem for MVP. Upgrade to cloud storage (S3, etc.) in future.
7. **WebSocket Architecture**: Separate WebSocket services (Master-WS, Node-WS) for scalability and separation of concerns.
8. **YT-DLP Primary**: Master uses YT-DLP for all YouTube downloads; Node uses YT-DLP for searches only.
9. **Real-Time**: WebSocket preferred, with polling fallback.
10. **Playback**: Admin controls only. Actual audio playback is out of scope for MVP (UI tracks state only).

---

## Status: Complete

This plan is ready for phase breakdown and sprint planning. Each phase can be implemented and tested independently before moving to the next.
