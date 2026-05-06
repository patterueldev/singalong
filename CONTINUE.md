# Singalong Project - Next Phase: Admin Auth Refresh & Queue Playback Integration

## Project Overview

Singalong is a distributed karaoke system with:
- **singalong-master** (backend): Central repository of video metadata, runs on public cloud
- **singalong-node** (backend): Local karaoke server, discovers and caches from master, serves API on :5002 (dev) / :8080 (release)
- **singalong-admin** (frontend): React/Vite UI for managing sessions, queues, and player controls, runs on :3001 (dev)
- **singalong-player** (iOS/Swift): Native player app that discovers node via mDNS and streams karaoke

### Current Development Setup
- **Admin UI**: `http://localhost:3001/` (hot reload)
- **Node API**: `http://localhost:8080/api/*` (mapped from :5002 in container)
- Admin calls API via `VITE_API_BASE_URL=http://localhost:8080/api`

### Release Setup
- **Embedded Admin**: Node image includes built admin UI, served at `/admin/` with embedded SQLite
- **Single Port**: :8080 routes both API (`/api/`) and Admin UI (`/admin/`)
- Same codebase, different deployments (dev=separate ports, release=embedded)

---

## Current Status

### ✅ Completed (Latest Session)
1. **Infrastructure Assessment & Refactoring**
   - Evaluated Nginx reverse proxy for dev setup (impossible without modifying source)
   - Simplified to separate ports: Admin :3001, Node API :8080
   - Vite HMR now works naturally without path rewriting

2. **Release Architecture**
   - Multi-stage Docker build: admin-builder → python-builder → runtime
   - Embeds React admin UI in Node image at `/app/app/static/admin`
   - Single container on :8080 serves both API and admin

3. **GitHub Actions & CI/CD**
   - Fixed build context: project root allows multi-stage dockerfile to access both apps
   - Added admin frontend checks to PR workflow (lint, type-check, build)
   - Removed temporary dev-build triggers

### 🔴 Blocking Issues
1. **Admin Auth Refresh Not Working**
   - Auth tokens expire (access: 1hr, refresh: 7 days)
   - Currently forced to logout/login to refresh
   - Token refresh mechanism exists but not being called
   - Need to fix `useAuth` hook to auto-refresh tokens before expiry

### 🟡 Next Phase: Queue Playback & Playback Controls
1. **Fix Admin Auth Refresh** (Priority 1)
   - Implement token refresh in `apps/singalong-admin/src/hooks/useAuth.ts`
   - Check Node API response for token expiry
   - Auto-refresh before calls fail with 401

2. **Queue Playback Integration** (Priority 2)
   - Admin UI: Queue management panel (add/remove songs, drag to reorder)
   - Player: Receive queue from Node, loop through in order
   - Node: Store current queue, broadcast queue changes via WebSocket

3. **Playback Controls on Admin** (Priority 2)
   - Play/Pause button
   - Skip to next song
   - Seek/Progress bar
   - Volume control
   - Player status display (now playing, time remaining)

4. **Queue Modifications on Admin** (Priority 2)
   - Add songs to queue from search results
   - Remove songs from queue
   - Reorder songs (drag-and-drop)
   - View entire queue with song details

5. **Optional: Download Progress on Admin** (Priority 3)
   - Display download progress for new songs
   - Show storage usage
   - Download queue status

---

## Technical Context for New Agent

### Authentication Flow
```
Client → POST /api/auth/admin {username, password}
← Returns: access_token (1hr), refresh_token (7 days), role

Client stores tokens in localStorage
Client sends: Authorization: Bearer {access_token} on all requests

Token Refresh:
Client (before 401) → POST /api/auth/refresh {refresh_token}
← Returns: new access_token + new refresh_token
Client updates localStorage
```

**File**: `apps/singalong-node/app/api/routes/auth.py`

### API Endpoints (Node)
```
POST   /api/auth/admin              - Admin login
POST   /api/auth/refresh            - Token refresh
GET    /api/sessions                - List sessions
POST   /api/sessions                - Create session
GET    /api/songs                   - Search/list songs
POST   /api/players/select          - Choose player for session
POST   /api/players/play            - Send play command
WebSocket /api/player/ws            - Player connection
```

**File**: `apps/singalong-node/app/api/routes/`

### Admin UI Structure
```
apps/singalong-admin/
├── src/
│   ├── pages/
│   │   ├── Login.tsx              - Login form
│   │   ├── Dashboard.tsx          - Main admin interface
│   ├── components/
│   │   ├── SessionsPanel.tsx      - Manage sessions
│   │   ├── PlaybackPanel.tsx      - Playback controls (needs integration)
│   │   ├── SelectPlayerModal.tsx  - Choose player
│   │   ├── CreateSessionModal.tsx - New session
│   │   └── ...
│   ├── hooks/
│   │   ├── useAuth.ts            - Auth state + token management (FIX THIS)
│   │   ├── useSessions.ts        - Session management
│   │   ├── useAvailablePlayers.ts
│   │   └── ...
│   ├── services/
│   │   ├── api.ts                - Axios client with interceptors
│   │   ├── sessionService.ts     - Session API calls
│   │   ├── playerService.ts      - Player API calls
│   │   └── ...
│   └── App.tsx                    - Router + layout
```

**Entry**: `src/main.tsx` → `src/App.tsx` → routes

### Key Design Decisions
- **Admin Auth**: All routes protected by `<ProtectedRoute>` wrapper in `App.tsx`
- **API Calls**: All go through axios in `services/api.ts` with auth interceptors
- **Token Storage**: localStorage (access_token, refresh_token)
- **HMR**: Vite dev server with fast reload (Node.js 20)
- **Type Safety**: TypeScript strict mode enabled

---

## Getting Started (For New Agent)

### 1. Understand the Project
- Read `docs/PROJECT_OVERVIEW.md` for system vision
- Read `apps/singalong-node/AGENTS.md` for Node service architecture
- Read `apps/singalong-admin/AGENTS.md` for Admin service architecture

### 2. Run Dev Environment
```bash
docker compose up -d
# Admin: http://localhost:3001/
# API: http://localhost:8080/api/health
```

### 3. Verify Auth Flow
```bash
# Login
curl -X POST http://localhost:8080/api/auth/admin \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Verify refresh endpoint exists
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<token_from_login>"}'
```

### 4. Check Admin Token State
- Open browser dev tools (F12)
- Go to Application → LocalStorage → http://localhost:3001
- Look for: access_token, refresh_token
- Check expiry: decode JWT at jwt.io

---

## Next Steps (In Order)

### Phase 1: Fix Auth Refresh
**Goal**: Auto-refresh tokens before they expire, no forced logout

**Files to Modify**:
- `apps/singalong-admin/src/hooks/useAuth.ts`
- `apps/singalong-admin/src/services/api.ts` (add refresh interceptor)

**Acceptance Criteria**:
- ✅ Access token refreshes automatically before expiry
- ✅ User stays logged in across session
- ✅ 401 errors are caught and token is refreshed, then request retried
- ✅ Logout works correctly

**Testing**:
```bash
# Wait for token to expire (or manually test with short expiry)
# Perform any API call
# Verify no forced logout
# Check localStorage for new tokens
```

---

### Phase 2: Queue Playback Integration
**Goal**: Player receives and plays songs from queue, Admin can manage queue

**Components to Create/Modify**:
- Admin: Queue panel with list/add/remove/reorder
- Node: Queue storage and WebSocket broadcast
- Player: Subscribe to queue changes, play in order

**Acceptance Criteria**:
- ✅ Admin can add songs to queue
- ✅ Admin can remove songs from queue
- ✅ Player receives queue and plays first song
- ✅ Queue updates broadcast to all players
- ✅ Skip to next song works

---

### Phase 3: Playback Controls on Admin
**Goal**: Admin UI has play/pause/seek/volume controls

**Components to Create**:
- PlaybackControls component
- Progress bar with seek
- Volume slider

**Acceptance Criteria**:
- ✅ Play/pause button works
- ✅ Seek bar works
- ✅ Volume control works
- ✅ Current time display updates

---

### Phase 4: Queue Modifications on Admin (Optional)
**Goal**: Admin can reorder queue, view full queue with metadata

**Acceptance Criteria**:
- ✅ Drag-and-drop reordering works
- ✅ Queue persists across refreshes
- ✅ Song metadata displayed (artist, duration, etc.)

---

## Important Notes

- **Do not modify** `apps/singalong-admin/vite.config.ts` without discussion (base path detection)
- **Do not create `.env` files** under `apps/*` - use root `.env` only
- **All API calls** must go through `apps/singalong-admin/src/services/api.ts`
- **Commits** must use format: `feat: Description` or `fix: Description`
- **Release builds** embed admin in Node, so changes work in both dev AND release

---

## Useful Resources

- API Documentation: http://localhost:8080/docs (Swagger UI)
- Node Health: http://localhost:8080/api/health
- GitHub: https://github.com/patterueldev/singalong
- Branch: `feature/player-queue-playback` (will be created for this phase)
