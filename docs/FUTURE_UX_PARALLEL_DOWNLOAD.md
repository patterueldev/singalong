# Future UX/Feature: Parallel Download with Async Enhancement

**Status**: Proposed (Post-MVP)  
**Priority**: Low-Medium (nice-to-have, not blocking)  
**Affects**: Frontend (Admin + Controller), Backend (Node + Master)  
**Effort**: ~12-18 hours  
**Prerequisites**: W2.4 + W3 (WebSocket server + fallbacks complete)

---

## Overview

Currently, the song download flow is **sequential**:
1. User pastes YouTube URL
2. Node validates URL → calls Master
3. Master queues download
4. **User waits** for download to finish
5. User sees enhancement screen (metadata edit)
6. User saves

This proposal introduces **parallel execution**:
1. User pastes YouTube URL
2. Node validates + immediately queues download on Master
3. User proceeds to enhancement screen **instantly**
4. Download progresses in background (visible via real-time progress)
5. User edits metadata while file downloads
6. User saves (metadata + file saved together when ready)

**Result**: User doesn't wait for download before proceeding—perceived performance improves significantly.

---

## User Experience Flow

```
User Input (YouTube URL/paste)
    ↓
URL Validation (server-side or client-side heuristic)
    ↓
Immediate Download Queue (fire-and-forget to Master)
    ↓
Navigation to Enhancement Screen (without awaiting download)
    ↓ (parallel)
┌─────────────────────────────┬──────────────────────────────┐
│  ENHANCEMENT SCREEN         │  BACKGROUND: DOWNLOAD        │
│ ─────────────────────────   │ ────────────────────────────  │
│ • Title field (editable)    │ • Progress: 0% → 100%        │
│ • Artist field              │ • Speed indicator            │
│ • Year, Language, etc.      │ • Status: downloading...     │
│ • Optional: AI enhance btn  │ • [Complete notification]    │
│                             │                               │
│ [Save] [Cancel]             │                               │
└─────────────────────────────┴──────────────────────────────┘
    ↓
User clicks [Save]
    ↓
Metadata + File Saved (if download complete)
or
Metadata Saved + File Marked Pending (race condition handling)
    ↓
Song Added to Songbook
```

---

## Architecture Analysis

### Current State (Foundation Already Exists)

✅ **Master-side capabilities** (already implemented):
- Async download queue with background processing
- WebSocket broadcast of download progress events
- GraphQL mutation accepts optional metadata fields
- Event handlers for download lifecycle

✅ **Node-side capabilities** (already implemented):
- GraphQL client can call Master mutations
- WebSocket listener receives all Master events
- Auto-sync on download:complete (W2.3)
- JWT authentication for all calls

✅ **Frontend capabilities** (already in place):
- Real-time WebSocket listeners for progress
- Routing between pages
- Form state management

### Changes Required

#### 1. **Backend: URL Validation** (MEDIUM complexity)

**Endpoint needed**: `GET /api/videos/validate?url={youtube_url}`

**What it does**:
- Accepts YouTube URL
- Returns metadata peek (title, duration, channel) + validation result
- Distinguishes song/karaoke content from random videos

**Implementation options**:
- **Option A (Lightweight)**: Client-side heuristic (keyword detection)
  - Pros: No server call, instant
  - Cons: Unreliable for non-English titles
- **Option B (Reliable)**: YT-DLP metadata peek
  - Pros: Accurate, uses existing integration
  - Cons: Takes 2-3 seconds per URL
- **Recommendation**: **Option B** (reliable > speed for validation)

**Code location**: `apps/singalong-master/app/api/routes/videos.py` (new route)

**Risk**: YT-DLP API rate limits if validation called frequently; add caching/throttling.

---

#### 2. **Backend: Incomplete Song Records** (MEDIUM complexity)

**Problem**: Download finishes AFTER metadata is saved.

**Solution**: Add "incomplete song" state to track pending files.

**Schema changes needed**:
```python
class Song(Base):
    # ... existing fields ...
    file_status: str = "pending"  # "pending" | "available" | "failed"
    file_downloaded_at: Optional[datetime] = None
    metadata_saved_at: Optional[datetime] = None
    # Track when user gave up on enhancement
    cancelled_at: Optional[datetime] = None
```

**Query logic**:
- When listing songs for controller, **exclude** songs with `file_status = "pending"` AND old `metadata_saved_at` (abandoned)
- Include songs with `file_status = "available"` (ready to use)

**Code locations**:
- `apps/singalong-node/app/models/db.py` (database schema)
- `apps/singalong-node/app/services/node_sync_service.py` (merge logic)

**Risk**: Added complexity to song state machine; must handle transitions carefully.

---

#### 3. **Backend: Concurrent Save Handler** (MEDIUM-HIGH complexity)

**Problem**: User submits metadata while download is 50% complete.

**Options**:

**Option A (Pessimistic)**: Block save until download 100% complete
- Pros: Simple, no race conditions
- Cons: Defeats purpose of parallel UX
- Not recommended

**Option B (Optimistic)**: Save metadata immediately, resolve file when available
- Pros: True parallelism, fast save
- Cons: Handle case where file never arrives (user cancels on Master)
- Recommended for best UX

**Implementation**:
```python
# When user clicks Save:
async def save_song_enhancement(song_id, metadata_updates):
    # 1. Update metadata immediately
    await db.update_song_metadata(song_id, metadata_updates)
    
    # 2. Check if file already synced
    if song.file_status == "available":
        return {"status": "ready", "song_id": song_id}
    
    # 3. If file still downloading, mark as "pending final sync"
    else:
        await db.mark_song_pending_final_sync(song_id)
        return {"status": "waiting_for_file", "song_id": song_id}
    
    # 4. WebSocket auto-sync will complete the process (W2.3)
```

**Code locations**:
- `apps/singalong-node/app/api/routes/songs.py` (new endpoint or modify existing)
- `apps/singalong-node/app/services/song_service.py` (business logic)

**Risk**: File arrives, metadata already saved = OK ✅. Metadata saved, file never arrives = song unusable (see Orphaned Records below).

---

#### 4. **Backend: Download Cancellation** (MEDIUM complexity)

**Problem**: User cancels enhancement before download completes.

**Solution**: Add cancellation endpoint to Master + cleanup handler.

**Endpoint needed**: `DELETE /api/videos/{video_id}/cancel-download`

**What happens**:
1. Node receives user cancel request
2. Node calls Master DELETE endpoint
3. Master stops download (if queued) or marks as cancelled (if in-progress)
4. Node receives cancel confirmation
5. Node marks song as "cancelled" in database

**Implementation**:
```python
# Master side
@router.delete("/api/videos/{video_id}/cancel-download")
async def cancel_download(video_id: str):
    service = get_download_service()
    result = await service.cancel_download(video_id)
    return {"video_id": video_id, "status": result}

# Node side
async def handle_user_cancel(song_id: str):
    video_id = await get_video_id(song_id)
    await master_client.post("/api/videos/{video_id}/cancel-download")
    await db.mark_song_cancelled(song_id)
```

**Code locations**:
- `apps/singalong-master/app/api/routes/videos.py` (cancel endpoint)
- `apps/singalong-master/app/services/master_download_service.py` (cancel logic)
- `apps/singalong-node/app/api/routes/songs.py` (cancel endpoint)
- `apps/singalong-node/app/services/song_service.py` (cancel handler)

**Risk**: If cancellation call fails, Master keeps downloading. Mitigate with cleanup jobs (see below).

---

#### 5. **Backend: Orphaned Record Cleanup** (LOW-MEDIUM complexity)

**Problem**: If user cancels (or network fails), Master has incomplete download + Node has incomplete record.

**Solution**: Periodic cleanup job.

**What gets cleaned up**:
- Downloads on Master with `status = "cancelled"` for >7 days
- Songs on Node with `file_status = "pending"` AND `metadata_saved_at` older than 7 days
- Downloaded video files that don't have corresponding database records

**Implementation**:
```python
# Add to Master background tasks
@periodic_task(interval=86400)  # Daily
async def cleanup_orphaned_downloads():
    old_downloads = await db.query_downloads(
        status="cancelled",
        created_before=now() - timedelta(days=7)
    )
    for download in old_downloads:
        await storage.delete_file(download.file_path)
        await db.delete_download(download.id)

# Add to Node background tasks
@periodic_task(interval=86400)  # Daily
async def cleanup_orphaned_songs():
    orphaned = await db.query_songs(
        file_status="pending",
        metadata_saved_before=now() - timedelta(days=7)
    )
    for song in orphaned:
        await db.delete_song(song.id)  # Remove if no playback history
```

**Code locations**:
- `apps/singalong-master/app/tasks/cleanup.py` (new file)
- `apps/singalong-node/app/tasks/cleanup.py` (new file)
- Both services' startup code (register periodic tasks)

**Risk**: None—cleanup is non-critical; better to keep 7-day orphans than risk false deletion.

---

#### 6. **Backend: Enhanced Error Handling** (LOW complexity)

**Current error scenarios handled**:
- ✅ Download fails (broadcast via event)
- ✅ File sync fails (logged, can retry)

**New scenarios to handle**:
- ❌ User saves metadata, then download fails before sync
  - Solution: Mark song with `file_status = "failed"`, show error to user
- ❌ Multiple users try to enhance same song in parallel
  - Solution: Lock per song, last writer wins (acceptable for MVP)
- ❌ File arrives but Node sync fails
  - Solution: Auto-retry via existing sync mechanism ✅

**Code locations**: Minimal changes, mostly in error handlers already existing.

---

### Frontend: Enhancement Screen Updates (LOW-MEDIUM complexity)

**singalong-admin** changes:
- Real-time progress bar fed by WebSocket progress events
- [Editable fields]: Title, Artist, Year, Language, Lyrics (optional)
- [Save] button: Submit metadata (don't wait for download)
- [Cancel] button: Stop download + remove incomplete record
- Status indicator: "Downloading 45% | 2.3 MB/s | ~2 min remaining"
- Behavior: Allow save at any point, show warning if download <100%

**singalong-controller** changes:
- Same UX as admin (but only for reserved sessions)
- Progress bar might be less critical (admin-focused feature)
- Can ship with admin first

**Code locations**:
- `apps/singalong-admin/src/pages/EnhanceSong.tsx` (new or modify)
- `apps/singalong-admin/src/hooks/useDownloadProgress.ts` (WebSocket progress hook)
- `apps/singalong-controller/src/pages/EnhanceSong.tsx` (mirror of admin)

---

## Implementation Roadmap

### Phase 1: URL Validation (2-4 hours)
- Add `/api/videos/validate` endpoint to Master
- Test with 10+ YouTube URLs
- Document behavior for non-English content

### Phase 2: Incomplete Song Records (3-4 hours)
- Update database schema
- Migration script for existing songs
- Queries to handle pending/available states

### Phase 3: Concurrent Save (2-3 hours)
- Modify save endpoint to not await download
- Handle metadata-only save
- Test race conditions

### Phase 4: Cancellation (2-3 hours)
- Add cancel endpoints (Master + Node)
- Wire up to Frontend buttons
- Test cleanup

### Phase 5: Orphan Cleanup (1-2 hours)
- Background jobs
- Logging for cleanup operations

### Phase 6: Frontend + Testing (3-4 hours)
- Enhancement screen redesign
- Progress bar component
- End-to-end testing (all 5 scenarios above)

**Total: ~13-20 hours** (includes testing & debugging)

---

## Risk Analysis

| Risk | Severity | Mitigation |
|------|----------|-----------|
| **YouTube API rate limits** | 🟡 MEDIUM | Cache validation results (1 hour TTL), add delay between calls |
| **Orphaned files consuming storage** | 🟡 MEDIUM | 7-day cleanup job, monitor disk usage alerts |
| **File arrives after metadata saved** | 🟡 MEDIUM | Designed for this—metadata + file merge on sync ✅ |
| **User cancels during save** | 🟢 LOW | Idempotent cancel endpoint, safe to retry |
| **Race: Multiple users enhance same video** | 🟢 LOW | Last writer wins, acceptable for MVP scale (5-15 users) |
| **Network fail during enhancement** | 🟢 LOW | Frontend retries, existing error handling covers |
| **File corrupted by download failure** | 🟢 LOW | Sync verifies file size/checksum, marks failed |

---

## Testing Strategy

**Unit Tests**:
- URL validation (valid/invalid YouTube URLs, non-English titles)
- Concurrent save (metadata arrives before/after file)
- Cancellation (idempotency, cleanup)

**Integration Tests**:
- Full parallel flow: paste → queue → enhance → save → songbook
- Cancel mid-download → verify cleanup
- Orphan cleanup job removes old records

**Load Tests** (optional):
- 5 concurrent downloads + enhancements
- 50 simultaneous URL validations (throttle check)

**Manual Testing**:
- Real YouTube URLs (music, karaoke, non-English)
- Cancel at various download percentages
- Network interruptions during enhancement

---

## Prerequisites Before Implementation

✅ **Must complete first**:
1. **W2.4**: Node's WebSocket server for local clients (needed for progress UI)
2. **W3**: Graceful fallback handling (REST + WebSocket hybrid)
3. **Master production readiness**: PostgreSQL, stable download queue

✅ **Should complete**:
- Jest/Vitest setup for Frontend tests
- Database migration framework finalized
- Background job scheduler (APScheduler or similar)

---

## Decision Checklist

Before starting, confirm:

- [ ] Is parallel UX worth the complexity? (measure user pain point)
- [ ] Will 7-day orphan cleanup strategy be acceptable?
- [ ] Can we validate YouTube URLs reliably? (non-English support)
- [ ] Is race condition handling (last-writer-wins) OK for product?
- [ ] Do we have bandwidth for testing edge cases?

---

## Alternatives

**Option 1: Keep Sequential Flow**
- Pros: Simple, no race conditions, predictable
- Cons: User waits 10-30 sec for download before proceeding
- **Recommendation**: Acceptable for MVP, can upgrade later

**Option 2: Partial Parallel (Client-side optimization)
- Queue download immediately, but keep user on same page
- Show progress in modal overlay, let them click "Go to Enhancement"
- Pros: Minimal backend changes, better UX
- Cons: Less dramatic improvement than full parallel
- **Recommendation**: Could be done as MVP improvement

**Option 3: Full Parallel (This Proposal)**
- Queue immediately, navigate away, show progress on enhancement screen
- Pros: Best perceived performance, modern UX
- Cons: Most complex, requires careful race handling
- **Recommendation**: Worth it post-MVP

---

## Related Documents

- [DOWNLOAD_DESIGN_MVP.md](DOWNLOAD_DESIGN_MVP.md) - Current sequential flow
- [BACKEND_PHASES.md](BACKEND_PHASES.md) - Backend roadmap
- [ADMIN_UI_SPECIFICATION.md](ADMIN_UI_SPECIFICATION.md) - Admin interface
- [API_CONTRACT_AUTHENTICATION.md](API_CONTRACT_AUTHENTICATION.md) - Auth details

---

## Approval & Timeline

**Status**: Proposed  
**Decision Needed**: Product decision on whether improvement is worth ~15 hours  
**Target Timeline**: Post-MVP (after W2.4 + W3, likely v1.2)

---

**Document Version**: 1.0  
**Created**: 2026-05-01  
**Last Updated**: 2026-05-01
