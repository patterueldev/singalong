# Singalong MVP Strategy

**Date**: 2026-04-28  
**Decision**: Session-based architecture for MVP (Option 3)  
**Status**: Planning phase

---

## Executive Summary

Rather than building separate admin CMSs (master-admin, node-admin), the MVP will use **session-based management**. Admins interact with the system through dedicated sessions, making the MVP scope tighter and the workflow more cohesive.

**Key Insight**: Everything in Singalong revolves around sessions anyway, so it makes sense for admin operations to use sessions too. No special paths, no separate databases, one paradigm for all users.

---

## Why Session-Based for MVP?

### Problems with Alternative Approaches

**Option 1: Master-Admin CMS First**
- ❌ Requires building CMS out of scope
- ❌ Separate auth path (master-admin only)
- ❌ Can't test real workflow until sessions are built
- ❌ Parallel development complexity
- ✅ Benefit: Direct master management (deferred to Phase 2)

**Option 2: Node-Admin CMS First**
- ❌ Requires building CMS out of scope
- ❌ Duplicate endpoints (via Node to Master)
- ❌ Can't test real workflow until sessions are built
- ❌ More complexity before MVP
- ✅ Benefit: Node-centric management (deferred to Phase 2)

**Option 3: Session-Based (CHOSEN)**
- ✅ No extra CMSs to build
- ✅ Single auth paradigm (everything through sessions)
- ✅ Can test real workflow immediately after B3b
- ✅ Production-ready for first party
- ✅ Future CMSs are just UI over existing APIs
- ✅ Minimal scope creep

### Benefits

1. **Architectural Consistency**
   - Users interact through sessions
   - Admins also interact through sessions
   - One paradigm, not multiple auth paths

2. **Faster to Market**
   - Less code to write
   - Fewer moving parts to test
   - Real end-to-end workflow testable sooner

3. **Production Ready**
   - Can host actual karaoke parties immediately
   - No "placeholder" features
   - Everything is real, nothing is fake

4. **Future Extensions**
   - CMSs become "nice UIs" over existing APIs
   - No architectural changes needed
   - Master-admin tools are addons, not requirements

5. **Simpler Testing**
   - Same auth flow for all user types
   - Session isolation is the only complexity
   - Fewer edge cases to handle

---

## The Default Admin Session (9999)

### Design

```
Session ID: 9999
├─ Always Active: Yes (never closes)
├─ Auto-Created: On first Master startup
├─ Access Control: Passcode + Admin Role
├─ Purpose: Administrative operations only
├─ Visibility: All superadmins
└─ Can Other Sessions Access It?: No (isolated)
```

### Why This Works

- **Testing**: Admin can join 9999 with passcode, add songs, invite others to demo session
- **Security**: Passcode prevents accidental joins; admin role check adds second barrier
- **Availability**: Always there; doesn't depend on an admin creating it
- **Isolation**: Songs added in 9999 are available to all sessions; but 9999-specific data isn't leaked
- **Operations**: Admins can manage master data (songs, etc.) without starting/ending a session

### Comparison to Trad Admin Panels

| Aspect | Traditional Admin Panel | Session 9999 |
|--------|------------------------|------------|
| Code Paths | Separate auth, separate endpoints | Same auth, same endpoints |
| Database | Special admin tables | Shared session tables |
| Testing Workflow | CMS first, then play | Play immediately with admin help |
| Complexity | More auth rules | Simpler, consistent |
| Future Changes | Risk breaking admin panel | Affects all sessions equally |

---

## MVP Development Roadmap

### Phase B3b: Session Management (2 days)
**Goal**: Implement 4-digit sessions with 9999 as admin default

**Deliverables**:
1. Session table (Master)
   - `id` (UUID)
   - `node_id` (which node owns it)
   - `session_id` (4-digit: "0000"-"9999")
   - `session_code` (passcode to join, can be NULL for public)
   - `title` (optional: "Party at Pat's", "Team Building")
   - `status` ("active", "ended")
   - `created_at`, `created_by_admin_id`
   - `is_admin_session` (boolean, TRUE only for 9999)

2. Session table (Node)
   - Same schema, synced from Master
   - Local cache for offline access

3. GraphQL mutations updated (Master)
   - `authenticateController(nickname, session_id, passcode?)`
     - Validates: session exists, status=active, passcode matches if required
   - `authenticateAdmin(username, password, session_id?)`
     - If session_id provided: joins that session
     - If not provided: joins default 9999
   - `authenticatePlayer(session_id, passcode?)`
     - Validates: session exists, only one player per session

4. Node endpoints
   - `POST /api/sessions` - Create new session (requires admin auth to 9999)
   - `GET /api/sessions` - List active sessions (admin view: all; user view: own only)
   - `DELETE /api/sessions/{id}` - End session (requires admin auth to 9999)

5. First-run migration
   - Create session 9999 automatically
   - Set passcode to config value (can be changed via API later)

### Phase B3c: Song Management (2-3 days)
**Goal**: Add songs to system through admin session 9999

**Deliverables**:
1. Song table (Master)
   - `id`, `title`, `artist`, `duration`, `youtube_url`, `file_path`, `status`

2. Endpoints (both Master and Node)
   - `POST /api/songs` - Add song from YT URL (requires auth + session 9999)
   - `GET /api/songs` - List all songs (available to all sessions)
   - `GET /api/songs/{id}` - Song details

3. YT-DLP integration
   - Identify song from URL
   - Fetch metadata
   - Download to storage
   - Mark as "ready" when complete

### Phase B3d: Reservations (1-2 days)
**Goal**: Queue management - users reserve songs

**Deliverables**:
1. Reservation table
   - `session_id`, `song_id`, `reserved_by` (username), `order`, `status`

2. Endpoints
   - `POST /api/reservations` - Reserve song in your session
   - `GET /api/reservations` - List queue for session
   - `PUT /api/reservations/{id}` - Update order (admin only)
   - `DELETE /api/reservations/{id}` - Cancel reservation

### Phase B3e: Playback (2-3 days)
**Goal**: Play songs, receive real-time updates

**Deliverables**:
1. WebSocket endpoint
2. Playback control messages (play, pause, next)
3. Live updates to all connected clients

### Phase C: Frontends (3-5 days)
**Goal**: Professional UIs for all three roles

1. **Admin UI** - Connect to Node, manage session 9999
2. **Controller UI** - Attendee app, reserve songs, view queue
3. **Player UI** - Playback device, show current song info

---

## Future Extensions (Post-MVP)

### Master-Admin CMS (Phase 2)
- Web dashboard at `master.example.com/admin`
- View/manage all nodes, sessions, songs globally
- User management
- Analytics

### Node-Admin CMS (Phase 2)
- Web dashboard at `node.example.com/admin`
- Manage only this node's sessions
- Local song cache management

### OAuth/SSO (Phase 2)
- Better authentication for admins
- User account system

---

## Session Architecture Deep Dive

See `SESSIONS_ARCHITECTURE.md` for detailed design.

---

## Summary Table

| Aspect | Details |
|--------|---------|
| **Admin Workflow** | Login → Join 9999 with passcode → Add songs/manage data |
| **User Workflow** | Create session → Join with code → Reserve songs → Sing |
| **Separation** | Passcode + role check prevents mixing of concerns |
| **Data Ownership** | Sessions own their reservations; songs are global |
| **Playback Device** | One per session; gets commands via WebSocket |
| **Future Admin CMS** | Just a UI wrapper, no backend changes needed |

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| 9999 becomes bottleneck if many ops | Medium | Add admin operations queue later |
| Passcode is simple auth | Low | Can upgrade to 2FA in Phase 2 |
| Session growth (many active) | Low | Database scaling is standard problem |
| Complexity hidden in mutations | Medium | Excellent test coverage, clear docs |

---

## Next Steps

1. ✅ Finalize this strategy (THIS DOCUMENT)
2. → Document session architecture in detail (SESSIONS_ARCHITECTURE.md)
3. → Implement B3b (Session management)
4. → Implement B3c (Song management)
5. → Proceed with queue, playback, frontends

