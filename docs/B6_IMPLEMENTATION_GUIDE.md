# B6 Song Enhancement: Implementation Guide & Testing

**Version**: 1.0  
**Status**: Production  
**Last Updated**: 2026-04-29

---

## How B6 Works: Step-by-Step

### Step 1: Identify Song (B5)

User sends a YouTube URL to the identify endpoint:

```bash
curl -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=8leAAwMIigI"}'
```

**Response** (raw metadata from yt-dlp):

```json
{
  "videoId": "8leAAwMIigI",
  "source": "youtube",
  "title": "Rick Astley - Never Gonna Give You Up (Video)",
  "artist": "",
  "duration": 213,
  "thumbnail": "https://i.ytimg.com/vi/8leAAwMIigI/maxresdefault.jpg",
  "year": "",
  "language": "",
  "url": "https://www.youtube.com/watch?v=8leAAwMIigI",
  "tags": ["rickastley", "nevergonnaguyyouup", "rickroll", ...]
}
```

**Note**: Identify returns raw metadata. Artist, year, language are empty because yt-dlp doesn't extract them reliably.

---

### Step 2: Enhance Song (B6) - Optional

User can optionally enhance the metadata using AI:

```bash
curl -X POST http://localhost:5002/api/songs/enhance \
  -H "Content-Type: application/json" \
  -d '{
    "videoId": "8leAAwMIigI",
    "source": "youtube",
    "title": "Rick Astley - Never Gonna Give You Up (Video)",
    "artist": "",
    "duration": 213,
    "thumbnail": "https://i.ytimg.com/vi/8leAAwMIigI/maxresdefault.jpg",
    "year": "",
    "language": "",
    "url": "https://www.youtube.com/watch?v=8leAAwMIigI",
    "tags": ["rickastley", "nevergonnaguyyouup", "rickroll", ...]
  }'
```

**Response** (enhanced metadata):

```json
{
  "videoId": "8leAAwMIigI",
  "source": "youtube",
  "title": "Never Gonna Give You Up",  // ← ENHANCED (removed artist prefix)
  "artist": "Rick Astley",              // ← ENHANCED
  "duration": 213,
  "thumbnail": "https://i.ytimg.com/vi/8leAAwMIigI/maxresdefault.jpg",
  "year": "1987",                       // ← ENHANCED
  "language": "en",                     // ← ENHANCED
  "url": "https://www.youtube.com/watch?v=8leAAwMIigI",
  "tags": ["rickastley", "nevergonnaguyyouup", "rickroll", ...],
  "lyrics": ""
}
```

**What Changed?**
- ✅ Title: Cleaned (removed "Video", removed artist prefix)
- ✅ Artist: Extracted from title and metadata
- ✅ Year: Identified from LLM's training knowledge
- ✅ Language: Detected from LLM's context

---

### Step 3: Download Song (B2) - Optional

User can now download with enhanced metadata:

```bash
curl -X POST http://localhost:5002/api/songs/download \
  -H "Content-Type: application/json" \
  -d '{
    "videoId": "8leAAwMIigI",
    "source": "youtube",
    "title": "Never Gonna Give You Up",
    "artist": "Rick Astley",
    "duration": 213,
    "year": "1987",
    "language": "en",
    ...
  }?reserve=true'
```

This sends to Master for download and optionally reserves the song.

---

## How Enhancement Works Internally

### Context Building Example

For title `"Rick Astley - Never Gonna Give You Up (Video)"`:

```
LLM Input Context:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Rick Astley - Never Gonna Give You Up (Video)
Current Artist: [empty]
Current Year: [empty]
Current Language: [empty]
Duration: 213 seconds

Tags: rickastley, nevergonnaguyyouup, rickroll, 1987, official...

YouTube Description:
(max 500 chars)
Rick Astley's official music video for "Never Gonna Give You Up"
Listen on Spotify: https://...

Examples:
Input:  "[Karaoke 0] Aqours - 未熟DREAMER ( Mijuku DREAMER )"
Output: { title: "未熟DREAMER", artist: "Aqours", year: 2016, language: "ja" }

Input:  "Bakamitai English Cover - Amalee"
Output: { title: "Bakamitai", artist: "Amalee", year: 2021, language: "en" }

Instructions:
- Extract the song TITLE (not the artist name, not video description)
- Extract the ARTIST name if available
- Infer the YEAR from description, metadata, or tags
- Detect the LANGUAGE from content (en, ja, es, etc)
- Return as JSON with these 4 fields
```

### LLM Response

OpenAI gpt-4o-mini returns:

```json
{
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "year": 1987,
  "language": "en"
}
```

**Note**: LLM returns `year` as integer (not string). The service converts it to string.

### Validation

Each field is validated:

```python
# Title validation
title = "Never Gonna Give You Up"
assert len(title) <= 200  # ✓ Pass

# Year validation
year = 1987
assert 1900 <= int(year) <= 2100  # ✓ Pass

# Language validation
language = "en"
assert language in SUPPORTED_LANGUAGES  # ✓ Pass (en is valid)

# All fields converted to strings
{
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "year": "1987",
  "language": "en"
}
```

---

## Error Handling Examples

### Scenario 1: No OpenAI Key Configured

```bash
curl -X POST http://localhost:5002/api/songs/enhance \
  -d '{...metadata...}'
```

**Response**: HTTP 200 OK with **original metadata unchanged**

```json
{
  "videoId": "8leAAwMIigI",
  "title": "Rick Astley - Never Gonna Give You Up (Video)",  // Original
  "artist": "",                                              // Original
  "year": "",                                                // Original
  ...
}
```

**Server log**:
```
INFO: OpenAI API key not configured, returning unenhanced metadata
```

---

### Scenario 2: OpenAI API Call Fails

(Network timeout, rate limit, auth error, etc)

```bash
curl -X POST http://localhost:5002/api/songs/enhance \
  -d '{...metadata...}'
```

**Response**: HTTP 200 OK with **original metadata unchanged**

```json
{
  "videoId": "8leAAwMIigI",
  "title": "Rick Astley - Never Gonna Give You Up (Video)",  // Original
  "artist": "",                                              // Original
  ...
}
```

**Server log**:
```
ERROR: OpenAI error: Connection timeout after 30s
INFO: Returning unenhanced metadata
```

---

### Scenario 3: LLM Response Invalid

(LLM returns malformed JSON, missing fields, etc)

```bash
curl -X POST http://localhost:5002/api/songs/enhance \
  -d '{...metadata...}'
```

**Response**: HTTP 200 OK with **original metadata unchanged**

```json
{
  "videoId": "8leAAwMIigI",
  "title": "Rick Astley - Never Gonna Give You Up (Video)",  // Original
  "artist": "",                                              // Original
  ...
}
```

**Server log**:
```
ERROR: Failed to parse LLM response: JSON decode error
INFO: Returning unenhanced metadata
```

---

### Scenario 4: Validation Fails (Partial Enhancement)

LLM returns valid data but year is out of range:

```python
LLM response: {
  "title": "Never Gonna Give You Up",  ✓ Valid
  "artist": "Rick Astley",             ✓ Valid
  "year": 9999,                        ✗ Invalid (> 2100)
  "language": "en"                     ✓ Valid
}
```

**Response**: HTTP 200 OK with **partially enhanced metadata**

```json
{
  "videoId": "8leAAwMIigI",
  "title": "Never Gonna Give You Up",  // ← ENHANCED
  "artist": "Rick Astley",             // ← ENHANCED
  "year": "",                          // ← ORIGINAL (validation failed)
  "language": "en",                    // ← ENHANCED
  ...
}
```

**Server log**:
```
WARNING: Year 9999 out of range (1900-2100), using original value
INFO: Returning partially enhanced metadata
```

---

## Test Results: Real Videos

### Test 1: Rick Astley - Never Gonna Give You Up

**Identify Response**:
```json
{
  "videoId": "8leAAwMIigI",
  "title": "Rick Astley - Never Gonna Give You Up (Video)",
  "artist": "",
  "year": "",
  "language": ""
}
```

**Enhance Response** (with OpenAI):
```json
{
  "videoId": "8leAAwMIigI",
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "year": "1987",
  "language": "en"
}
```

**Result**: ✅ Correctly cleaned and enhanced

---

### Test 2: Aqours - 未熟DREAMER

**Identify Response**:
```json
{
  "videoId": "x_6nob9_WLc",
  "title": "[Karaoke 0] Aqours - 未熟DREAMER ( Mijuku DREAMER )",
  "artist": "",
  "year": "",
  "language": ""
}
```

**Enhance Response** (with OpenAI):
```json
{
  "videoId": "x_6nob9_WLc",
  "title": "未熟DREAMER",
  "artist": "Aqours",
  "year": "2016",
  "language": "ja"
}
```

**Result**: ✅ Extracted Japanese title and artist correctly

---

### Test 3: Bakamitai

**Identify Response**:
```json
{
  "videoId": "gV7DPYgOBMM",
  "title": "Bakamitai lyrics (eng sub)",
  "artist": "",
  "year": "",
  "language": ""
}
```

**Enhance Response** (with OpenAI):
```json
{
  "videoId": "gV7DPYgOBMM",
  "title": "Bakamitai",
  "artist": "",
  "year": "2006",
  "language": "ja"
}
```

**Result**: ✅ Cleaned title, detected year and language

---

## Enabling OpenAI Enhancement

### 1. Get API Key

Visit: https://platform.openai.com/api-keys

Create new secret key and copy it.

### 2. Set Environment Variable

```bash
export OPENAI_KEY=sk-...your-key-here...
```

### 3. Rebuild Docker Containers

```bash
docker-compose down
docker-compose up -d --build
```

### 4. Verify

```bash
docker logs singalong-node | grep -i openai
```

Should see:
```
INFO: OpenAI API key configured (sk-...xxxx)
```

### 5. Test

```bash
curl -X POST http://localhost:5002/api/songs/enhance \
  -H "Content-Type: application/json" \
  -d '{...metadata...}'
```

Should return enhanced metadata (not original).

---

## Cost & Performance

### Per Enhancement

- **Time**: ~3-5 seconds (one API call)
- **Cost**: ~$0.00008 (gpt-4o-mini is cheap)
- **Tokens**: ~250 input + ~75 output

### At Scale

| Volume | Time | Cost |
|--------|------|------|
| 1 song | ~4s | $0.00008 |
| 10 songs | ~40s | $0.00080 |
| 100 songs | ~6.5 min | $0.008 |
| 1,000 songs | ~65 min | $0.08 |
| 10,000 songs | ~11 hours | $0.80 |

---

## Summary

**B6 Enhancement Flow**:
1. User calls `/api/songs/enhance` with identify response
2. Service builds context from metadata
3. Calls OpenAI with prompt + examples
4. Parses & validates response
5. Returns enhanced metadata (or original on error)
6. **Always HTTP 200 OK** (enhancement is optional)

**Why This Approach?**
- ✅ Simple (single API call)
- ✅ Fast (~3-5 seconds)
- ✅ Cheap (~$0.00008 per song)
- ✅ Reliable (graceful degradation)
- ✅ Deterministic (temperature=0)

See also:
- [B6_ARCHITECTURE.md](B6_ARCHITECTURE.md) - Detailed architecture
- [B6_FLOWCHARTS_AND_DIAGRAMS.md](B6_FLOWCHARTS_AND_DIAGRAMS.md) - Visual flowcharts
- [../apps/singalong-node/AGENTS.md](../apps/singalong-node/AGENTS.md) - Service documentation
