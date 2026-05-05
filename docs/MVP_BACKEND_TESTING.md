# Singalong MVP Backend - Complete Testing Guide

This guide walks through the entire MVP workflow from session creation to playback queue management.

---

## Prerequisites

- Node service running on `http://localhost:5002`
- Master service running (can be remote)
- `curl` or Postman for API testing
- Docker containers healthy

---

## Complete End-to-End Test Scenario

### Step 1: Verify Services are Running

```bash
# Check Node health
curl -s http://localhost:5002/health | jq .
# Expected: { "status": "healthy", "service": "singalong-node" }

# Check Master health
curl -s https://singalongmaster-dev.nicenature.space/health | jq .
# Expected: { "status": "healthy", "service": "singalong-master" }
```

---

### Step 2: Authenticate as Admin

Admin is needed to create sessions and manage players.

```bash
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:5002/api/auth/admin \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "singalong123"
  }')

echo $ADMIN_RESPONSE | jq .

# Extract tokens
ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token')
ADMIN_REFRESH=$(echo $ADMIN_RESPONSE | jq -r '.refresh_token')

echo "Admin Token: $ADMIN_TOKEN"
echo "Admin Refresh: $ADMIN_REFRESH"
```

**Expected Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800,
  "role": "admin"
}
```

---

### Step 3: Create a Karaoke Session

```bash
SESSION_RESPONSE=$(curl -s -X POST http://localhost:5002/api/sessions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Summer Party 2026",
    "vibes": "party",
    "max_users": 50
  }')

echo $SESSION_RESPONSE | jq .

# Extract session data
SESSION_ID=$(echo $SESSION_RESPONSE | jq -r '.id')
SESSION_CODE=$(echo $SESSION_RESPONSE | jq -r '.session_code')

echo "Session ID: $SESSION_ID"
echo "Session Code: $SESSION_CODE"
```

**Expected Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "session_code": "ABC123",
  "title": "Summer Party 2026",
  "vibes": "party",
  "max_users": 50,
  "created_at": "2026-04-29T10:30:00Z",
  "created_by": "admin-uuid"
}
```

---

### Step 4: Authenticate as First Attendee

```bash
ATTENDEE1_RESPONSE=$(curl -s -X POST http://localhost:5002/api/auth/controller \
  -H "Content-Type: application/json" \
  -d "{
    \"nickname\": \"Alice\",
    \"session_id\": \"$SESSION_CODE\"
  }")

echo $ATTENDEE1_RESPONSE | jq .

# Extract tokens
ATTENDEE1_TOKEN=$(echo $ATTENDEE1_RESPONSE | jq -r '.access_token')
ATTENDEE1_ID=$(echo $ATTENDEE1_RESPONSE | jq -r '.user_id')

echo "Attendee 1 Token: $ATTENDEE1_TOKEN"
echo "Attendee 1 ID: $ATTENDEE1_ID"
```

**Expected Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800,
  "role": "controller",
  "user_id": "uuid"
}
```

---

### Step 5: Authenticate as Second Attendee

```bash
ATTENDEE2_RESPONSE=$(curl -s -X POST http://localhost:5002/api/auth/controller \
  -H "Content-Type: application/json" \
  -d "{
    \"nickname\": \"Bob\",
    \"session_id\": \"$SESSION_CODE\"
  }")

ATTENDEE2_TOKEN=$(echo $ATTENDEE2_RESPONSE | jq -r '.access_token')
ATTENDEE2_ID=$(echo $ATTENDEE2_RESPONSE | jq -r '.user_id')

echo "Attendee 2 ID: $ATTENDEE2_ID"
```

---

### Step 6: Identify First Song

Alice wants to sing "Never Gonna Give You Up" by Rick Astley.

```bash
SONG1_IDENTIFY=$(curl -s -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  }')

echo $SONG1_IDENTIFY | jq .

SONG1_TITLE=$(echo $SONG1_IDENTIFY | jq -r '.title')
SONG1_ARTIST=$(echo $SONG1_IDENTIFY | jq -r '.artist')
SONG1_DURATION=$(echo $SONG1_IDENTIFY | jq -r '.duration')

echo "Song: $SONG1_TITLE by $SONG1_ARTIST ($SONG1_DURATION seconds)"
```

**Expected Response**:
```json
{
  "video_id": "dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "duration": 212,
  "thumbnail": "https://i.ytimg.com/...",
  "year": 1987,
  "channel": "Rick Astley Official",
  "language": "en",
  "description": "The official music video...",
  "view_count": 1234567890,
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

---

### Step 7: Enhance Song Metadata

Alice edits the song details before downloading.

```bash
SONG1_ENHANCE=$(curl -s -X PUT http://localhost:5002/api/songs/enhance \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" \
  -d '{
    "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up (Remaster)",
    "artist": "Rick Astley",
    "year": 1987,
    "language": "en",
    "genre": "Pop",
    "duration_seconds": 212,
    "additional_notes": "Great party song!"
  }')

echo $SONG1_ENHANCE | jq .
```

**Expected Response**:
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up (Remaster)",
  "artist": "Rick Astley",
  "year": 1987,
  "language": "en",
  "genre": "Pop",
  "duration_seconds": 212,
  "additional_notes": "Great party song!",
  "enhanced_at": "2026-04-29T10:30:15Z",
  "ready_to_download": true
}
```

---

### Step 8: Request Song Download

Alice requests the Master to download the song.

```bash
SONG1_DOWNLOAD=$(curl -s -X POST http://localhost:5002/api/songs/download-request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" \
  -d '{
    "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up (Remaster)",
    "artist": "Rick Astley",
    "year": 1987,
    "language": "en",
    "genre": "Pop",
    "duration_seconds": 212
  }')

echo $SONG1_DOWNLOAD | jq .

SONG1_ID=$(echo $SONG1_DOWNLOAD | jq -r '.song_id')
DOWNLOAD1_ID=$(echo $SONG1_DOWNLOAD | jq -r '.download_id')

echo "Song ID: $SONG1_ID"
echo "Download ID: $DOWNLOAD1_ID"
```

**Expected Response**:
```json
{
  "status": "downloading",
  "song_id": "550e8400-e29b-41d4-a716-446655440001",
  "download_id": "550e8400-e29b-41d4-a716-446655440002",
  "message": "Download queued. Check status with GET /api/songs/{song_id}/download-status",
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

---

### Step 9: Check Download Status

```bash
# Check immediately (will be downloading)
curl -s http://localhost:5002/api/songs/$SONG1_ID/download-status \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" | jq .

# Wait a few seconds and check again
sleep 3

curl -s http://localhost:5002/api/songs/$SONG1_ID/download-status \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" | jq .
```

**Expected Response (downloading)**:
```json
{
  "song_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "downloading",
  "progress_percent": 45,
  "duration_seconds": 212,
  "file_size_mb": 150,
  "estimated_time_remaining_seconds": 60,
  "error_message": null,
  "created_at": "2026-04-29T10:30:00Z",
  "started_at": "2026-04-29T10:30:05Z",
  "completed_at": null,
  "file_path": null
}
```

**Expected Response (completed)**:
```json
{
  "song_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "completed",
  "progress_percent": 100,
  "duration_seconds": 212,
  "file_size_mb": 150,
  "estimated_time_remaining_seconds": 0,
  "error_message": null,
  "created_at": "2026-04-29T10:30:00Z",
  "started_at": "2026-04-29T10:30:05Z",
  "completed_at": "2026-04-29T10:35:45Z",
  "file_path": "s3://singalong-master/songs/550e8400.mp4"
}
```

---

### Step 10: Reserve Song 1

Once downloaded, Alice reserves it for the session.

```bash
RES1=$(curl -s -X POST http://localhost:5002/api/sessions/$SESSION_ID/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE1_TOKEN" \
  -d "{
    \"song_id\": \"$SONG1_ID\",
    \"user_id\": \"$ATTENDEE1_ID\"
  }")

echo $RES1 | jq .

RES1_ID=$(echo $RES1 | jq -r '.reservation_id')
RES1_POSITION=$(echo $RES1 | jq -r '.position')

echo "Reservation 1 ID: $RES1_ID"
echo "Position: $RES1_POSITION"
```

**Expected Response**:
```json
{
  "reservation_id": "550e8400-e29b-41d4-a716-446655440010",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "song_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440003",
  "position": 1,
  "status": "pending",
  "reserved_at": "2026-04-29T10:35:50Z",
  "started_at": null,
  "completed_at": null
}
```

---

### Step 11: Identify and Reserve Second Song

Bob wants to sing a different song. Identify it.

```bash
SONG2_IDENTIFY=$(curl -s -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE2_TOKEN" \
  -d '{
    "url": "https://www.youtube.com/watch?v=9bZkp7q19f0"
  }')

echo $SONG2_IDENTIFY | jq '.title, .artist'

# Download it (same process as steps 8-9)
SONG2_DOWNLOAD=$(curl -s -X POST http://localhost:5002/api/songs/download-request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE2_TOKEN" \
  -d '{
    "youtube_url": "https://www.youtube.com/watch?v=9bZkp7q19f0",
    "title": "Song by Bob",
    "artist": "Some Artist",
    "year": 2020,
    "genre": "Rock",
    "duration_seconds": 180
  }')

SONG2_ID=$(echo $SONG2_DOWNLOAD | jq -r '.song_id')

# Wait for download to complete
sleep 5

# Reserve it
RES2=$(curl -s -X POST http://localhost:5002/api/sessions/$SESSION_ID/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ATTENDEE2_TOKEN" \
  -d "{
    \"song_id\": \"$SONG2_ID\",
    \"user_id\": \"$ATTENDEE2_ID\"
  }")

echo $RES2 | jq .

RES2_ID=$(echo $RES2 | jq -r '.reservation_id')
```

**Bob's reservation should be at position 2**

---

### Step 12: View Complete Queue

Both songs are now in the queue. View the complete queue.

```bash
QUEUE=$(curl -s http://localhost:5002/api/sessions/$SESSION_ID/queue)

echo $QUEUE | jq .
```

**Expected Response**:
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "queue": [
    {
      "position": 1,
      "reservation_id": "550e8400-e29b-41d4-a716-446655440010",
      "song_id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Never Gonna Give You Up (Remaster)",
      "artist": "Rick Astley",
      "reserved_by": "Alice",
      "status": "pending",
      "duration_seconds": 212
    },
    {
      "position": 2,
      "reservation_id": "550e8400-e29b-41d4-a716-446655440011",
      "song_id": "550e8400-e29b-41d4-a716-446655440002",
      "title": "Song by Bob",
      "artist": "Some Artist",
      "reserved_by": "Bob",
      "status": "pending",
      "duration_seconds": 180
    }
  ],
  "current_position": 0,
  "total": 2
}
```

---

### Step 13: Mark Song 1 as Playing (Admin)

The admin marks the first song to start playing.

```bash
PLAYING=$(curl -s -X PUT http://localhost:5002/api/reservations/$RES1_ID/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "status": "playing"
  }')

echo $PLAYING | jq .
```

**Expected Response**:
```json
{
  "reservation_id": "550e8400-e29b-41d4-a716-446655440010",
  "status": "playing",
  "started_at": "2026-04-29T10:36:00Z",
  "updated_at": "2026-04-29T10:36:00Z"
}
```

---

### Step 14: View Queue Again

Check that current position updated.

```bash
curl -s http://localhost:5002/api/sessions/$SESSION_ID/queue | jq '.current_position, .queue[0].status'
```

---

### Step 15: Mark Song 1 as Completed

After the song finishes, mark it as completed.

```bash
sleep 5

COMPLETED=$(curl -s -X PUT http://localhost:5002/api/reservations/$RES1_ID/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "status": "completed"
  }')

echo $COMPLETED | jq .
```

---

### Step 16: Queue Auto-Updates

Song 2 should now be at position 1 (still pending).

```bash
curl -s http://localhost:5002/api/sessions/$SESSION_ID/queue | jq '.queue[] | {position, title, status}'
```

---

### Step 17: Cancel a Reservation

Admin can cancel reservations to skip songs.

```bash
# Cancel song 2
DELETE_RES=$(curl -s -X DELETE http://localhost:5002/api/sessions/$SESSION_ID/reservations/$RES2_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Delete response: $DELETE_RES"

# Check queue is now empty
curl -s http://localhost:5002/api/sessions/$SESSION_ID/queue | jq '.total'
# Expected: 0
```

---

## Summary

This complete workflow demonstrates:

✅ Session creation and management  
✅ Multi-user authentication  
✅ Song identification from YouTube  
✅ Metadata enhancement  
✅ Async downloads  
✅ Download progress tracking  
✅ Song reservations  
✅ Auto-positioned queue management  
✅ Playback status updates  
✅ Reservation cancellation  
✅ Automatic queue reorganization  

---

## Troubleshooting

### Song Identify Returns 404

**Cause**: YouTube video not found or removed  
**Solution**: Try a different YouTube URL

### Download Stuck on "Downloading"

**Cause**: Master service issue or network timeout  
**Solution**: Check Master service logs: `docker logs singalong-master`

### Reservation Fails with 409

**Cause**: Song already reserved in session  
**Solution**: Check existing reservations: `GET /api/sessions/{id}/reservations`

### Authentication Token Expired

**Cause**: Token older than 1 hour  
**Solution**: Re-authenticate with original endpoint

---

## Performance Notes

- Song identification: 10-30 seconds (YouTube extraction)
- Song download: 30-300 seconds (depends on file size)
- API responses: < 200ms (typical)
- Queue operations: < 50ms (instant)

