# Download Mechanism Design (MVP Simplification)

## Overview

For MVP, we've simplified the download mechanism to allow flexible re-downloads and ignore duplicate validation. This trades strict data consistency for operational simplicity—we can easily fix corrupted downloads without manual database cleanup.

## Key Design Decisions

### 1. Allow Re-downloading Same Videos

**Decision**: Remove duplicate validation. Users can identify and download the same YouTube video multiple times.

**Rationale**:
- Allows fixing corrupted or incomplete downloads
- Allows updating song metadata without manual intervention
- Avoids complex state management (pending, queued, failed, etc.)
- MVP focus: simplicity over strict validation

**Implementation**:
- `/api/songs/identify` endpoint no longer checks if video exists on Master
- `/api/songs/download` endpoint allows re-downloading—existing draft is deleted and recreated
- `requestSongDownload` GraphQL mutation deletes existing draft before creating new one

### 2. Override Existing Draft Records

**Decision**: When downloading a video that's already in progress, replace the old draft with a new one.

**Rationale**:
- Prevents stuck downloads from blocking future attempts
- Users can retry failed downloads without manual cleanup
- Avoids "duplicate is already queued" errors

**Example**:
```
1st attempt: User downloads gV7DPYgOBMM, starts downloading
2nd attempt: User downloads gV7DPYgOBMM again (same or different metadata)
Result: Old draft deleted, new draft created, new download starts
```

### 3. Song Status Values

Define four song statuses to track lifecycle and integrity:

| Status | Meaning | When Used |
|--------|---------|-----------|
| **DRAFT** | Metadata extracted, not yet downloaded | Initial state after identify |
| **ACTIVE** | File downloaded and verified intact | Ready for syncing to nodes, reservations |
| **ARCHIVED** | Song deliberately removed (e.g., copyright takedown) | Excluded from search and sync |
| **CORRUPTED** | File missing or integrity check failed | Identified during sync—marked for re-download |

**Note**: DraftSong records use a different workflow: `pending` → `downloading` → `completed` → `failed` → (cleanup/retry)

### 4. Query/Sync Only ACTIVE Songs

**Decision**: When syncing songs from Master to Node, only sync ACTIVE songs.

**Rationale**:
- DRAFT songs are not complete yet
- ARCHIVED songs are intentionally excluded
- CORRUPTED songs need re-download before distribution
- Simplifies Node's view of what songs are available

**Implementation Checklist** (Future phases):
- [ ] Filter queries to check `status = 'ACTIVE'`
- [ ] Verify file integrity during sync
- [ ] Mark as CORRUPTED if file not found or checksum fails
- [ ] Cleanup mechanism for stale DRAFT songs

### 5. Diagnostic Endpoint (Future - B4)

Add Master endpoint to diagnose song integrity:

```
GET /api/admin/diagnose/songs
GET /api/admin/diagnose/songs/{id}
```

Returns:
```json
{
  "song_id": "...",
  "title": "...",
  "status": "active",
  "file_path": "/data/master/videos/...",
  "file_exists": true,
  "file_size": 20691525,
  "file_valid": true,
  "last_checked": "2026-04-29T17:55:56Z",
  "issues": []
}
```

Can mark songs as CORRUPTED if:
- File doesn't exist on disk
- File size is 0 or suspiciously small
- Checksum/hash mismatch (if implemented)
- Downloaded timestamp is very old (stale)

## Migration Path

### Phase B1–B2 (Current)
- Implement re-download simplification
- Remove duplicate checks
- Status field exists but only "DRAFT" is used actively

### Phase B3 (Sync)
- On first sync, mark all successful downloads as "ACTIVE"
- Check file integrity and mark as "CORRUPTED" if issues found
- Query only ACTIVE songs

### Phase B4+ (Optional)
- Add diagnostic endpoint
- Implement checksum verification
- Auto-cleanup for old DRAFT songs
- Archive mechanism for copyright takedowns

## Files Modified

| File | Change |
|------|--------|
| `apps/singalong-master/app/models/db_models.py` | Updated status comment to include all values |
| `apps/singalong-master/app/graphql/schema.py` | Removed duplicate check; allow draft overwriting |
| `apps/singalong-node/app/api/routes/songs.py` | Removed duplicate/queue checks from `/identify` |

## Testing the Changes

### Test 1: Re-identify and re-download same video
```bash
# First identify
curl -X POST http://localhost:5002/api/songs/identify \
  -H "Authorization: Bearer TOKEN" \
  -d '{"url": "https://www.youtube.com/watch?v=8leAAwMIigI"}'

# Should work ✓
# Response: metadata for Rick Astley

# Second identify (same video)
curl -X POST http://localhost:5002/api/songs/identify \
  -H "Authorization: Bearer TOKEN" \
  -d '{"url": "https://www.youtube.com/watch?v=8leAAwMIigI"}'

# Should also work (no 409 error) ✓
# Response: same metadata
```

### Test 2: Download, then download again
```bash
# Download first time
curl -X POST http://localhost:5002/api/songs/download \
  -H "Authorization: Bearer TOKEN" \
  -d '{ ... metadata ... }'

# Response: 202 Accepted, draft created ✓

# Download again (same videoId)
curl -X POST http://localhost:5002/api/songs/download \
  -H "Authorization: Bearer TOKEN" \
  -d '{ ... same metadata ... }'

# Response: 202 Accepted, previous draft deleted, new draft created ✓
# No "conflict" error
```

### Test 3: Check status
```bash
curl http://localhost:5002/api/songs/downloads \
  -H "Authorization: Bearer TOKEN" | jq '.[] | {videoId, status}'

# Both downloads should show with their current status (downloading, completed, failed, etc)
```

## Future Enhancements

- [ ] Implement checksum-based integrity verification
- [ ] Add automatic cleanup for stale DRAFT songs (>X hours)
- [ ] Archive mechanism for legal/copyright removals
- [ ] Audit log for why songs marked as CORRUPTED
- [ ] Manual mark-as-active endpoint for ops team
- [ ] Batch re-download for CORRUPTED songs

---

**Status**: ✅ MVP Implemented  
**Decision Date**: 2026-04-29  
**Approved By**: User  
**Next Review**: After Phase B3 (Sync)
