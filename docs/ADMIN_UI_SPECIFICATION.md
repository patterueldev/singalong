# Admin UI Specification - Session Management Interface

## Overview

The admin panel is the primary interface for managing singalong sessions. It provides real-time controls for playback, queue management, downloads, and participant oversight.

**Target Users**: Session organizers/admins  
**Platform**: Web application (React)  
**Backend**: Node service `/api/sessions/*` endpoints

---

## Layout Architecture

The admin interface uses a **4-panel grid layout** on a dark background:

```
┌─────────────────────────────────────────────────────────────┐
│                    Session Header                            │
│  [Session Title] [Code: XXXXX] | Vibes: Normie | 8 attendees│
└─────────────────────────────────────────────────────────────┘
┌──────────────────────────┬──────────────────────────────────┐
│                          │                                  │
│   TOP-LEFT PANEL         │      TOP-RIGHT PANEL             │
│   (Playback Control)     │      (Downloads List)            │
│                          │                                  │
│   • Play/Pause/Skip      │   • Active downloads (in-flight) │
│   • Volume control       │   • Downloaded songs (cached)    │
│   • Current player       │   • Download queue               │
│   • Player selection     │   • Failed downloads             │
│                          │                                  │
└──────────────────────────┴──────────────────────────────────┘
┌──────────────────────────┬──────────────────────────────────┐
│                          │                                  │
│   BOTTOM-LEFT PANEL      │    BOTTOM-RIGHT PANEL            │
│   (Queue / Songbook)     │    (Attendees List)              │
│                          │                                  │
│   • Reserved songs queue │   • Participant list             │
│   • Songbook search      │   • Nickname + role display      │
│   • Add to queue         │   • Join/leave status            │
│   • Reorder songs        │   • Real-time updates            │
│   • Download songs       │                                  │
│                          │                                  │
└──────────────────────────┴──────────────────────────────────┘
```

---

## Panel Details

### Session Header

**Status**: Fixed header above all panels  
**Content**: Session metadata  

**Elements**:
- **Session Title** (editable by admin/creator)
- **Session Code** (read-only, copiable for joining)
- **Vibes Tag** (visual indicator, editable)
- **Attendee Count** (real-time updated via WebSocket)
- **Session Status** (active/ended, with indicator)
- **Leave/End Session** button (admin/creator only)

**Data Source**: 
```
GET /api/sessions/{sessionId}
```

---

### TOP-LEFT PANEL: Playback Control

**Dimensions**: 50% width, top half  
**Purpose**: Manage what's currently playing and select audio output devices

#### Playback Controls Section

**Components**:
- **Current Song Display**
  - Song title, artist, duration
  - Thumbnail/album art
  - Progress bar with time indicator
  - Updated via WebSocket (real-time progress)

- **Playback Controls**
  - Play/Pause button (toggle)
  - Previous track button
  - Next track button (skip)
  - Loop mode button (off/one/all)

- **Volume Control**
  - Volume slider (0-100%)
  - Mute button
  - Volume indicator icon

**Data Source**:
```
GET /api/sessions/{sessionId}/playback (polling or WebSocket)
```

#### Player Selection Section

**Purpose**: Select which player/speakers broadcast the karaoke audio

**Components**:
- **Available Players List**
  - Player name (device-advertised)
  - IP address + port
  - Connection status (connected/disconnected)
  - Signal strength indicator (WiFi)
  
- **Player Selection**
  - Radio buttons or dropdown to select active player
  - "Broadcast to All" option
  - Player priority/queue if multiple devices available

- **Player Management**
  - Authorize new player (when discovered)
  - Forget player button
  - Restart/reconnect player action

**Data Source**:
```
GET /api/sessions/{sessionId}/players (to be implemented)
WebSocket: player presence announcements
```

**Interactions**:
- Selecting a player sends audio to that device
- Only one player can broadcast at a time
- Switching players pauses and resumes playback

---

### TOP-RIGHT PANEL: Downloads List

**Dimensions**: 50% width, top half  
**Purpose**: Monitor and manage song downloads

#### Active Downloads Section

**Components**:
- **Download Queue (In-Flight)**
  - Song title + artist
  - Progress bar (percent complete)
  - Size indicator (MB downloaded / total MB)
  - Speed indicator (KB/s)
  - ETA (estimated time remaining)
  - Pause/Cancel buttons per download

**Auto-Update**: 
- Poll `/api/songs/downloads/status` every 1-2 seconds
- Or use WebSocket for real-time updates

#### Downloaded Songs (Cached) Section

**Components**:
- **Local Cache List**
  - Song title + artist
  - File size (MB)
  - Download date
  - Play count (times played in this session)
  - Delete button (remove from cache)

**Data Source**:
```
GET /api/songs/downloads/cached (list local files)
```

#### Download Failed Section

**Components**:
- **Failed Downloads**
  - Song title + artist
  - Error reason (e.g., "Video removed", "Network timeout")
  - Retry button
  - Remove from list button
  - Timestamp of failure

**Auto-Clear**: Failed downloads auto-dismiss after 5 minutes

#### UI States

**Empty State** (nothing downloading):
- "No downloads in progress"
- "All songs are cached and ready to play"

**Downloading State** (active downloads):
- Progress bars animate
- Speed/ETA update in real-time
- Can pause individual downloads

**Completed State** (all cached):
- Shows total cached songs count
- Shows total local storage used
- Cache management options

---

### BOTTOM-LEFT PANEL: Queue / Songbook

**Dimensions**: 50% width, bottom half  
**Purpose**: Manage the song queue and browse available songs

#### Reserved Songs Queue Section

**Components**:
- **Queue List** (scrollable)
  - Row per song: [Position] [Title - Artist] [Duration] [Reserved By] [Actions]
  - Current playing song highlighted (bold, different background)
  - Color coding: paused (yellow), finished (gray), upcoming (white)

- **Queue Actions** (per row)
  - Up/Down arrows (reorder, admin/creator only)
  - Remove button (trash icon)
  - Play next (priority move to top)
  - View song details (expands row)

- **Queue Statistics**
  - Total songs in queue: N
  - Total duration: HH:MM
  - Songs remaining: N

**Data Source**:
```
GET /api/sessions/{sessionId}/queue
```

#### Songbook Search Section

**Components**:
- **Search Bar**
  - Input: song title, artist, or tag
  - Real-time search (debounced 500ms)
  - Filters: genre, year, language
  - Sort options: relevance, title, artist, date added

- **Songbook Results** (scrollable)
  - Row per song: [Title - Artist] [Duration] [Genre] [Status] [Action]
  - Status indicators:
    - ✓ Already reserved (faded, show "Already queued")
    - ✓ Downloaded (green checkmark)
    - ✗ Not downloaded (gray, shows "Download required")
    - ⚠ Downloading (progress bar)

- **Add to Queue**
  - Button per song (or double-click)
  - If not downloaded, prompts: "Download and add to queue?" → Yes/No
  - Adds to end of queue (admin can reorder)
  - Toast notification: "Added to queue"

**Data Source**:
```
GET /api/songs/songbook?sessionId={sessionId}&limit=50&offset=0
  (includes reserved_in_session and download_status fields)
```

#### Download Song Section

**Components**:
- **Add Song via URL**
  - Input field: "Paste YouTube URL or song identifier"
  - Button: "Search" or "Download"
  - Optional: "Add to queue after download" checkbox

- **Search YT**
  - Uses Node's search service to find songs on YouTube
  - Results shown in popup/modal
  - User selects one, preview metadata
  - Confirm download

- **Manual Metadata Entry**
  - Title, Artist, Lyrics fields (optional)
  - For user to enhance metadata before download
  - Save and download button

---

### BOTTOM-RIGHT PANEL: Attendees List

**Dimensions**: 50% width, bottom half  
**Purpose**: Monitor and manage session participants

#### Attendees Section

**Components**:
- **Attendee List** (scrollable)
  - Row per attendee: [Nickname] [Role] [Joined At] [Status] [Actions]
  - Roles: admin, controller (guest)
  - Status indicator: 🟢 online, 🔴 offline, 🟡 idle (no activity 5+ min)

- **User Info** (expandable per row)
  - Full nickname
  - Device type (phone/tablet/browser)
  - IP address (for admins)
  - Last activity timestamp
  - Songs reserved by this user (count)

- **Attendee Actions**
  - Kick/Remove user (admin only)
  - Make admin (promote, admin only)
  - View user's queue items (filter)
  - Message/notify user (future)

#### Attendees Statistics Section

**Components**:
- **Count Indicators**
  - Total attendees: N
  - Online: N
  - Offline: N
  - Awaiting approval: N (if user whitelist feature enabled)

- **Session Invite**
  - "Invite Link" (copiable)
  - Shows: node.domain/join?code=XXXXX
  - QR code (optional, for mobile)
  - Can also generate "admin invite" link (pre-authentication)

#### Real-Time Updates

**WebSocket Events**:
- User joined: + attendee row
- User left: - attendee row
- User came online/offline: status indicator change
- User queued song: refresh count, maybe toast notification

**Data Source**:
```
GET /api/sessions/{sessionId}/attendees
WebSocket: /ws/sessions/{sessionId}/attendees
```

---

## Data Flow & Interactions

### Queue Management Flow

```
User Action: "Add song to queue"
     ↓
Frontend: Check if downloaded
     ↓
If not downloaded → Prompt to download
     ↓
POST /api/sessions/{sessionId}/queue
{
  "song_id": "song-uuid",
  "reserved_by": "user-uuid",
  "auto_download": true
}
     ↓
Backend: Create Reservation record
         If auto_download: Trigger download
     ↓
Response: QueueItemResponse with queue_id
     ↓
Frontend: Add to queue list, animate in
         WebSocket notifies all attendees
     ↓
Attendees see new song in queue (real-time)
```

### Playback Flow

```
User Action: "Skip to next song" / "Play"
     ↓
Frontend: POST /api/sessions/{sessionId}/playback/next
         or PATCH /api/sessions/{sessionId}/playback/play
     ↓
Backend: Update Playback record
         Notify Node players via WebSocket
     ↓
Players: Receive playback command, skip/pause/play
         Send back confirmation
     ↓
Frontend: Update UI (progress bar, current song)
         WebSocket streams playback progress
```

### Download Flow

```
User Action: Download song
     ↓
Frontend: POST /api/songs/download
{
  "video_id": "youtube-id",
  "source": "youtube"
}
     ↓
Backend: Queue download, return task_id
         Stream progress via WebSocket
     ↓
Frontend: Show in "Downloads" panel
         Update progress bar in real-time
     ↓
Completion: Move to "Downloaded" section
           Auto-available for queue
```

---

## Real-Time Features

### WebSocket Events

**Session Updates**:
- `session.updated` - Title/vibes/status changed
- `session.ended` - Session ended by admin
- `attendee.joined` - New user connected
- `attendee.left` - User disconnected
- `attendee.updated` - Nickname or role changed

**Queue Updates**:
- `queue.added` - Song added to queue
- `queue.removed` - Song removed
- `queue.reordered` - Queue position changed
- `playback.started` - Song started playing
- `playback.paused` - Song paused
- `playback.progress` - Progress update (every 1s when playing)
- `playback.ended` - Song finished

**Download Updates**:
- `download.started` - Download begins
- `download.progress` - Progress update
- `download.completed` - Download finished
- `download.failed` - Download error

### Polling Strategy (Fallback)

If WebSocket unavailable:
- Playback status: Poll every 1 second
- Queue: Poll every 2 seconds
- Attendees: Poll every 3 seconds
- Downloads: Poll every 500ms

---

## User Permissions Matrix

| Action | Admin | Creator | Controller |
|--------|-------|---------|------------|
| Edit session title/vibes | ✓ | ✓ | ✗ |
| End session | ✓ | ✓ | ✗ |
| Play/Pause/Skip | ✓ | ✓ | ✗ |
| Select player | ✓ | ✓ | ✗ |
| Reorder queue | ✓ | ✓ | ✗ |
| Remove others' songs | ✓ | ✗ | ✗ |
| Kick attendee | ✓ | ✗ | ✗ |
| View attendee list | ✓ | ✓ | ✓ |
| Add song to queue | ✓ | ✓ | ✓ |
| Pause own song | ✓ | ✓ | ✓ |
| Search songs | ✓ | ✓ | ✓ |

---

## Responsive Behavior

### Desktop (1920px+)
- Full 4-panel layout
- All controls visible
- Side-by-side panels as specified

### Tablet (768px - 1024px)
- 2x2 grid maintained
- Panels stack vertically if needed
- Touch-friendly buttons (48px minimum)

### Mobile (< 768px)
- Panels toggle via tabs
- One panel visible at a time
- Bottom navigation bar for switching

---

## Design System Requirements

### Colors (Dark Mode Only)
- **Background**: #16171d
- **Surface**: #1f2937
- **Primary**: #c084fc (purple)
- **Success**: #10b981 (green)
- **Warning**: #f59e0b (amber)
- **Danger**: #ef4444 (red)
- **Text**: #9ca3af (gray)
- **Text Muted**: #6b7280

### Typography
- **Headers**: Larger, bold
- **Labels**: Medium, medium weight
- **Values**: Medium, regular weight
- **Status indicators**: Small, monospace

### Components
- **Buttons**: Primary (purple), secondary (gray), danger (red)
- **Inputs**: Dark background, light borders
- **Progress bars**: Animated, color-coded (green=success, amber=warning)
- **Lists**: Hover highlight, alternating rows (optional)
- **Modals**: Centered, dark overlay

---

## Session Setup Flow (Admin Perspective)

1. **Login** → Admin dashboard
2. **Create Session** → Form: title, vibes, max_users (optional)
3. **Session Created** → Redirected to session room
4. **Select Player** → Choose speakers/output device
5. **Invite Attendees** → Share code or QR code link
6. **Wait for Joins** → Attendee list updates in real-time
7. **Start Playing** → Add songs, queue them, play via player
8. **Manage** → Reorder queue, skip, pause, change player volume
9. **End Session** → End button, session archived

---

## Error Handling & Edge Cases

### Error States
- **Network Error**: "Lost connection to server" banner, auto-reconnect indicator
- **Download Failed**: "Download failed: [reason]" in Downloads panel with retry
- **Player Offline**: "Player disconnected" warning, can select different player
- **Queue Empty**: "No songs queued, add from songbook"
- **Session Ended**: "Session has ended" modal, redirect to dashboard

### Edge Cases
- Multiple admins in same session → All can control
- Player switches during playback → Pause, switch, resume
- Song removed while queued → Remove from queue, notify attendees
- User closes tab → Status becomes "offline", can rejoin
- Network lag → Show "syncing..." indicator, lock controls temporarily

---

## API Endpoints Required

### Existing (Already Implemented)
- `GET /api/sessions/{sessionId}` - Session details
- `GET /api/sessions/{sessionId}/queue` - Queue list
- `POST /api/sessions/{sessionId}/queue` - Add to queue
- `DELETE /api/sessions/{sessionId}/queue/{queueId}` - Remove
- `PATCH /api/sessions/{sessionId}/queue/{queueId}/change-order` - Reorder
- `GET /api/sessions/{sessionId}/playback` - Current playback
- `GET /api/sessions/{sessionId}/attendees` - Attendee list

### To Be Implemented
- `PUT /api/sessions/{sessionId}` - Update session (title/vibes)
- `DELETE /api/sessions/{sessionId}` - End session
- `GET /api/songs/songbook?sessionId={id}` - Search songs with reservation status
- `POST /api/sessions/{sessionId}/playback/play` - Start playback
- `POST /api/sessions/{sessionId}/playback/pause` - Pause playback
- `POST /api/sessions/{sessionId}/playback/next` - Skip to next
- `POST /api/sessions/{sessionId}/players/select` - Select player (to be designed)
- `GET /api/songs/downloads/status` - Download progress
- `GET /api/songs/downloads/cached` - List cached songs
- `POST /api/songs/download` - Start download
- WebSocket: `/ws/sessions/{sessionId}` - Real-time updates

---

## Implementation Priority

### Phase 1 (MVP)
- [ ] Session Header (metadata, title)
- [ ] Playback Controls (play/pause/skip, no player selection yet)
- [ ] Queue List (display, add, remove)
- [ ] Attendees List (display only, no kick yet)
- [ ] Downloads List (basic display, no progress yet)
- [ ] Songbook Search (title only)

### Phase 2
- [ ] Player Selection (device picker)
- [ ] Download Progress (real-time)
- [ ] Queue Reorder (drag-and-drop or arrow buttons)
- [ ] Advanced Search (filters, tags)
- [ ] Attendee Management (kick, promote)

### Phase 3 (WebSockets)
- [ ] Real-time updates (joined/left/queue changes)
- [ ] Live playback progress
- [ ] Instant download status

---

## Document Version

- **Created**: 2026-04-30
- **Last Updated**: 2026-04-30
- **Status**: WIP (Pending Frontend Implementation)
- **Reference**: `docs/PROJECT_OVERVIEW.md`, `docs/SESSIONS_ARCHITECTURE.md`
