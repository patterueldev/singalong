# Sessions Architecture

**Document**: Detailed design of how sessions work in Singalong  
**Audience**: Developers, implementers  
**Version**: 1.0

---

## Session Concepts

### What is a Session?

A **session** is a bounded context for a karaoke party or administrative work. It represents:
- A specific time/place where people gather to sing karaoke
- A queue of songs that will be sung
- A set of reservations (who's singing what)
- A playback device showing the current song

Sessions are **created by admins** and **joined by users** with a 4-digit code + optional passcode.

### Session Lifecycle

```
┌──────────────┐
│   Created    │  Admin creates session "1234"
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Active    │  Users join with code + passcode
│   (singing)  │  Songs get queued and played
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Ended     │  Admin closes session
│  (revoked)   │  New joiners blocked
└──────────────┘
```

### Special Case: Session 9999 (Admin)

Session 9999 is a permanent session for administrative operations:
- Created automatically on Master startup
- Always "active" (never ends)
- Protected by passcode + admin role check
- Admin joins 9999 to add songs/manage system
- Songs added in 9999 are available to all sessions

---

## Database Schema

### Master Service: `sessions` Table

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    node_id UUID NOT NULL,                    -- Which node owns this session
    session_id VARCHAR(4) NOT NULL,           -- "0000" to "9999"
    session_code VARCHAR(255),                -- Passcode to join (NULL = public)
    title VARCHAR(255),                       -- "Party at Pat's", "Team Building"
    description TEXT,                         -- Optional: what's this session about?
    status VARCHAR(20) NOT NULL,              -- "active" or "ended"
    created_at TIMESTAMP NOT NULL,
    created_by_admin_id UUID NOT NULL,        -- Which admin created it
    ended_at TIMESTAMP,                       -- When did it end?
    is_admin_session BOOLEAN DEFAULT FALSE,   -- TRUE only for 9999
    
    UNIQUE(node_id, session_id),              -- One session ID per node
    FOREIGN KEY(created_by_admin_id) REFERENCES users(id),
    CHECK(session_id BETWEEN '0000' AND '9999')
);
```

### Node Service: `sessions` Table (Cache)

```sql
-- Same schema as Master, synced periodically
-- Used for offline session lookups
-- Last synced timestamp added
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    node_id UUID NOT NULL,
    session_id VARCHAR(4) NOT NULL,
    session_code VARCHAR(255),
    title VARCHAR(255),
    description TEXT,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    created_by_admin_id UUID NOT NULL,
    ended_at TIMESTAMP,
    is_admin_session BOOLEAN DEFAULT FALSE,
    synced_at TIMESTAMP NOT NULL,             -- When was this cached?
    
    UNIQUE(node_id, session_id)
);
```

---

## Authentication Flow with Sessions

### Controller (User) Authentication

```
User's Browser                          Node Service
      │                                      │
      ├─ POST /api/auth/controller ──────────>
      │   {                                   │
      │     "nickname": "Pat",               │
      │     "session_id": "1234",            │
      │     "session_code": "secret"         │
      │   }                                   │
      │                                      │
      │                  <─────── Node calls Master GraphQL
      │                           authenticateController(
      │                             nickname: "Pat",
      │                             session_id: "1234",
      │                             node_id: node's_id,
      │                             session_code: "secret"
      │                           )
      │                                      │
      │                  Master responds:    │
      │                  ✅ Session exists   │
      │                  ✅ Status: active   │
      │                  ✅ Code matches     │
      │                                      │
      │                  Node generates JWT  │
      │<────── 201 Created ────────────────────
      │   {
      │     "access_token": "JWT...",
      │     "refresh_token": "JWT...",
      │     "role": "controller"
      │   }
      │
      ├─ User now has token valid for 1 hour
      └─ Can POST /api/reservations with this token
```

### Admin Authentication

```
Admin's Browser                         Node Service
      │                                      │
      ├─ POST /api/auth/admin ──────────────>
      │   {                                   │
      │     "username": "admin_pat",         │
      │     "password": "secret123"          │
      │   }                                   │
      │                                      │
      │                  <─────── Node calls Master GraphQL
      │                           authenticateAdmin(
      │                             username: "admin_pat",
      │                             password: "secret123",
      │                             node_id: node's_id
      │                           )
      │                                      │
      │                  Master responds:    │
      │                  ✅ Credentials valid│
      │                  ✅ User is admin    │
      │                                      │
      │                  IMPLICIT:           │
      │                  ✅ Auto-join session 9999
      │                                      │
      │                  Node generates JWT  │
      │<────── 201 Created ────────────────────
      │   {
      │     "access_token": "JWT...",
      │     "session_context": "9999",
      │     "role": "admin"
      │   }
      │
      └─ Admin can now POST /api/songs (allowed for session 9999)
```

### Player (Playback Device) Authentication

```
Playback Device                         Node Service
      │                                      │
      ├─ POST /api/auth/player ─────────────>
      │   {                                   │
      │     "session_id": "1234"             │
      │   }                                   │
      │                                      │
      │                  <─────── Node calls Master GraphQL
      │                           authenticatePlayer(
      │                             session_id: "1234",
      │                             node_id: node's_id
      │                           )
      │                                      │
      │                  Master checks:      │
      │                  ✅ Session exists   │
      │                  ✅ Status: active   │
      │                  ❌ No other player  │
      │                     connected?       │
      │                                      │
      │                  If another player   │
      │                  already connected:  │
      │                  ❌ 409 Conflict     │
      │                                      │
      │                  Node generates JWT  │
      │<────── 201 Created ────────────────────
      │   {
      │     "access_token": "JWT...",
      │     "session_context": "1234",
      │     "role": "player"
      │   }
      │
      └─ Player now receives playback commands via WebSocket
```

---

## Session Isolation

### What is Isolated?

Each session has its own:
- **Reservations queue** - Only this session's songs
- **User list** - Only people who joined this session
- **Playback state** - Only one device per session

### What is Shared?

Across all sessions:
- **Song library** - All songs available to all sessions
- **User accounts** - Same user (nickname) can be in multiple sessions
- **Admin operations** - Only in session 9999

### Example

```
Session 1234 "Pat's Party"
├─ Users: Pat, Alex, Jordan
├─ Reservations:
│  ├─ "Bohemian Rhapsody" (Pat)
│  ├─ "Blinding Lights" (Alex)
│  └─ "Shape of You" (Jordan)
└─ Currently Playing: "Bohemian Rhapsody"

Session 5678 "Office Karaoke"
├─ Users: Sam, Casey, Morgan
├─ Reservations:
│  ├─ "Don't Stop Believin'" (Sam)
│  └─ "Wannabe" (Casey)
└─ Currently Playing: "Don't Stop Believin'"

Session 9999 "Admin" (ALWAYS ACTIVE)
├─ Users: admin_pat
├─ Operations: Add songs, manage system
└─ Reservations: None (administrative only)

Song Library (Global)
├─ "Bohemian Rhapsody" - Available to 1234, 5678, 9999
├─ "Blinding Lights" - Available to 1234, 5678, 9999
└─ "Don't Stop Believin'" - Available to 1234, 5678, 9999
```

---

## Session Operations

### Create Session (Admin Only)

```
Endpoint: POST /api/sessions
Authentication: Admin JWT + Session 9999 context
Request:
{
  "session_id": "1234",
  "title": "Pat's Birthday Party",
  "session_code": "birthday123"  // Optional: NULL = public
}

Response: 201 Created
{
  "id": "uuid",
  "session_id": "1234",
  "title": "Pat's Birthday Party",
  "status": "active",
  "created_at": "2026-04-28T13:00:00Z"
}

Validation:
✓ Admin role required (checked via JWT)
✓ Session 9999 context required
✓ session_id must be "0000"-"9999"
✓ session_id must be unique for this node
✓ title is optional but recommended
```

### Join Session (Any User)

```
Endpoint: POST /api/auth/controller (for users)
Request:
{
  "nickname": "Pat",
  "session_id": "1234",
  "session_code": "birthday123"  // Required if session has code
}

Response: 201 Created
{
  "access_token": "JWT...",
  "refresh_token": "JWT...",
  "session_id": "1234",
  "role": "controller"
}

Validation (in Master GraphQL):
✓ Session "1234" exists
✓ Session status = "active"
✓ session_code matches (if provided)
```

### List Sessions

```
Endpoint: GET /api/sessions
Authentication: User JWT

Query Parameters:
- status=active|ended (default: active)
- node_id=uuid (default: current node)

Response: 200 OK
{
  "sessions": [
    {
      "id": "uuid",
      "session_id": "1234",
      "title": "Pat's Birthday",
      "status": "active",
      "created_at": "...",
      "user_count": 5
    },
    {
      "id": "uuid",
      "session_id": "5678",
      "title": "Office Party",
      "status": "active",
      "created_at": "...",
      "user_count": 3
    }
  ]
}

Rules:
- Non-admin users see all active sessions (discovery)
- Admin users see all sessions (active + ended)
- Session 9999 only visible to admins
```

### End Session (Admin Only)

```
Endpoint: DELETE /api/sessions/{id}
Authentication: Admin JWT + Session 9999 context
Response: 204 No Content

Effect:
- Session status → "ended"
- ended_at → now
- No new users can join
- Existing users remain but can't do new actions
- Reservations preserved (for history)
```

---

## Session State Transitions

### Valid State Transitions

```
CREATED ──────────> ACTIVE ──────────> ENDED
                     ▲                    │
                     │                    │
                     └────── (Cannot reopen)
```

### Rules

- Session starts as "active" when created
- Only active sessions accept new users
- Once ended, cannot be reopened (create a new one)
- Ended sessions preserved for history

---

## Session 9999 Special Behavior

### Creation

- Automatically created on Master startup
- If it somehow gets deleted, recreate on next startup
- Always created with status = "active"
- Passcode set from `ADMIN_SESSION_CODE` env var

### Access

```
Role      Can Join 9999?   Requirements
────────────────────────────────────────
admin     ✅ Yes           Username + password
controller ❌ No            (always 401)
player    ❌ No             (always 401)
superadmin ✅ Yes           (via /api/auth/superadmin on Master)
```

### Operations in 9999

Only these endpoints work with session 9999 context:
- `POST /api/songs` - Add songs
- `POST /api/sessions` - Create new sessions
- `DELETE /api/sessions/{id}` - End sessions
- Admin-only endpoints

Regular operations (reserve, play) don't apply to 9999 (it's not a party session).

---

## Sync Between Master and Node

### Strategy

Node keeps a local cache of sessions for:
1. Offline session lookup (if Master is down)
2. Faster authentication (no network call)
3. Local session management (create/list)

### Sync Process

```
┌─────────────────────────────────────┐
│ Every 5 minutes:                    │
│                                     │
│ Node → Master: GET /api/sessions    │
│ Master responds: All sessions       │
│ Node: Update local cache            │
└─────────────────────────────────────┘
```

### When to Create Sessions on Node vs Master

| Operation | Where | Why |
|-----------|-------|-----|
| Create session | Node → Master | Master is source of truth |
| List sessions | Node (cache) | Fast, always available |
| Validate session | Both | Master validates, Node caches result |
| End session | Node → Master | Master is source of truth |

---

## Error Scenarios

### Scenario: User Tries to Join Closed Session

```
User Request:
POST /api/auth/controller
{
  "nickname": "Pat",
  "session_id": "1234"
}

Master GraphQL Check:
Session 1234 status = "ended" ❌

Response: 400 Bad Request
{
  "detail": "Session 1234 has ended and is no longer accepting new members"
}
```

### Scenario: Wrong Passcode

```
User Request:
POST /api/auth/controller
{
  "nickname": "Pat",
  "session_id": "1234",
  "session_code": "wrongcode"
}

Master GraphQL Check:
Session code "wrongcode" != "birthday123" ❌

Response: 401 Unauthorized
{
  "detail": "Incorrect session code"
}
```

### Scenario: Session Doesn't Exist

```
User Request:
POST /api/auth/controller
{
  "nickname": "Pat",
  "session_id": "0000"
}

Master GraphQL Check:
No session with ID "0000" ❌

Response: 404 Not Found
{
  "detail": "Session 0000 not found on this node"
}
```

### Scenario: Player Already Connected

```
Playback Device 1: Already connected to session 1234
Playback Device 2: Tries to connect to session 1234

Master GraphQL Check:
Session 1234 already has player_connection ❌

Response: 409 Conflict
{
  "detail": "Another player device is already connected to this session.
             End that connection first."
}
```

---

## Implementation Checklist (B3b)

- [ ] Create sessions table on Master
- [ ] Create sessions table on Node
- [ ] Create session 9999 on first startup
- [ ] Add session validation to GraphQL mutations
- [ ] Implement Node endpoints (CRUD)
- [ ] Implement sync from Master to Node
- [ ] Write tests for all scenarios
- [ ] Document error handling
- [ ] Update API contract documentation

---

## Future Enhancements (Post-MVP)

1. **Session Expiration**
   - Auto-close sessions after X hours of inactivity
   - Configurable per node

2. **Session Notifications**
   - WebSocket broadcast when session ends
   - Notify clients to disconnect

3. **Session Analytics**
   - Track which users attended which sessions
   - Track song popularity per session
   - Generate reports

4. **Advanced Session Features**
   - Scheduled sessions (set time in future)
   - Capacity limits (max users per session)
   - VIP reservations (skip queue)
   - Themes/vibes (influence recommendations)

