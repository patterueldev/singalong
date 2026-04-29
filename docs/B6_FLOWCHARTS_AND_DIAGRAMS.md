# B6 Song Enhancement: Flowcharts & Diagrams

**Version**: 1.0  
**Status**: Production  
**Last Updated**: 2026-04-29

---

## 1. Complete Enhancement Flow

```
START: POST /api/songs/enhance
       {song metadata from identify}
              │
              ▼
    ┌─────────────────────────┐
    │ Validate request schema │
    │ (Pydantic validation)   │
    └────────┬────────────────┘
             │
      VALID? ├─ NO ─────────────────────────────────┐
             │                                        │
             YES                                      │
             │                                        │
             ▼                                        │
    ┌──────────────────────────────┐                │
    │ Check if OpenAI key ready?   │                │
    │ (config.openai_api_key set)  │                │
    └────────┬─────────┬───────────┘                │
             │         │                             │
             YES       NO                            │
             │         │                             │
             │         └────────────────────────┐   │
             │                                  │   │
             ▼                                  ▼   ▼
    ┌──────────────────────────┐    ┌──────────────────────┐
    │ 1. Fetch YouTube         │    │ Return original      │
    │    description           │    │ metadata unchanged   │
    │ (if source="youtube")    │    │ (graceful degrade)   │
    │ - Call yt-dlp            │    │ HTTP 200 OK          │
    │ - Extract description    │    └──────────────────────┘
    │ - Limit to 500 chars     │             ▲
    │ - On error: continue     │             │
    └────────┬─────────────────┘             │
             │                               │
             ▼                               │
    ┌──────────────────────────────┐        │
    │ 2. Build LLM context         │        │
    │ Combine:                     │        │
    │ - Title                      │        │
    │ - Artist                     │        │
    │ - Year + Language (if set)   │        │
    │ - Tags (first 20)            │        │
    │ - Description (if fetched)   │        │
    │ - Examples from prompt       │        │
    └────────┬─────────────────────┘        │
             │                               │
             ▼                               │
    ┌──────────────────────────────────┐    │
    │ 3. Call OpenAI API               │    │
    │ gpt-4o-mini (temperature=0)      │    │
    │ - Timeout: 30 seconds            │    │
    │ - Retry: None (fail fast)        │    │
    └────────┬─────────────┬───────────┘    │
             │             │                 │
         SUCCESS        ERROR                │
             │             │                 │
             ▼             │                 │
    ┌──────────────────────┐│                │
    │ Parse LLM response   ││                │
    │ - Extract JSON       ││                │
    │ - Convert to strings ││                │
    │   (handle int types) ││                │
    └────────┬─────────────┘│                │
             │              │                │
         VALID?             │                │
             │              │                │
      ┌──────┴───────┐      │                │
      │              │      │                │
      YES            NO     │                │
      │              │      │                │
      ▼              ▼      ▼                │
    ┌────────────────────────────────┐      │
    │ 4. Validate fields             │      │
    │ - Title: max 200 chars         │      │
    │ - Year: 1900-2100 range        │      │
    │ - Language: ISO 639-1 code     │      │
    │ - Convert all to strings       │      │
    │                                │      │
    │ Per-field strategy:            │      │
    │ ├─ If valid: use enhanced      │      │
    │ └─ If invalid: use original    │      │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ 5. Merge results             │
    │ Enhanced title +              │
    │ Original videoId, url,        │
    │ thumbnail, tags, etc          │
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ 6. Serialize to response      │
    │ SongMetadataResponse (Py)     │
    │ Pydantic validation           │
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ HTTP 200 OK                  │
    │ {enhanced metadata JSON}      │
    └──────────────────────────────┘

END: Enhancement complete (success or gracefully degraded)
```

---

## 2. Error Handling Tree

```
Enhancement Request
    │
    ├─ [Schema Validation Error]
    │   └─→ Return HTTP 400 (bad request)
    │
    ├─ [OpenAI Key Missing]
    │   └─→ Return original metadata (HTTP 200 OK)
    │       Log: "OpenAI key not configured"
    │
    ├─ [YouTube Description Fetch Failed]
    │   └─→ Continue with other context
    │       (description optional)
    │
    ├─ [OpenAI API Call Failed]
    │   │   (timeout, rate limit, auth error, etc)
    │   └─→ Return original metadata (HTTP 200 OK)
    │       Log: "OpenAI error: {error_message}"
    │
    ├─ [LLM Response Parsing Failed]
    │   │   (not JSON, missing fields, etc)
    │   └─→ Return original metadata (HTTP 200 OK)
    │       Log: "Failed to parse LLM response"
    │
    ├─ [LLM Response Validation Failed]
    │   │   (year out of range, invalid language code, etc)
    │   └─→ Return partially enhanced metadata
    │       (valid fields enhanced, invalid fields original)
    │       Log: "Validation failed for field: {field}"
    │
    └─ [Success]
        └─→ Return enhanced metadata (HTTP 200 OK)

KEY PRINCIPLE: Enhancement is optional.
               Any error → return original metadata unchanged.
               HTTP 200 OK always (failure is not a user error).
```

---

## 3. Context Building Components

```
┌─────────────────────────────────────────────────┐
│           Song Metadata Input                    │
├─────────────────────────────────────────────────┤
│ From identify endpoint:                          │
│ ├─ videoId: "x_6nob9_WLc"                       │
│ ├─ title: "[Karaoke 0] Aqours - 未熟DREAMER..."  │
│ ├─ artist: "" (empty)                           │
│ ├─ year: "" (empty)                             │
│ ├─ language: "" (empty)                         │
│ ├─ duration: 352                                │
│ ├─ tags: ["aqours", "love live", ...]          │
│ └─ url: "https://www.youtube.com/watch?v=..."  │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌──────────────────────┐  ┌────────────────────────┐
│ Static Context       │  │ Dynamic Context        │
│ (from metadata)      │  │ (from YouTube)         │
├──────────────────────┤  ├────────────────────────┤
│ ├─ Title             │  │ ├─ Description         │
│ ├─ Artist (if set)   │  │ │  (fetched via ytdlp) │
│ ├─ Year (if set)     │  │ │  (max 500 chars)     │
│ ├─ Language (if set) │  │ └─ Optional (on error: │
│ ├─ Duration          │  │    continue anyway)    │
│ └─ Tags (first 20)   │  └────────────────────────┘
└──────────────────────┘
        │                     │
        └──────────┬──────────┘
                   │
                   ▼
        ┌────────────────────┐
        │ Combine into       │
        │ LLM Prompt         │
        │                    │
        │ Format:            │
        │ Title: {...}       │
        │ Current Artist: {..│
        │ Tags: {...}        │
        │ Description: {...} │
        │                    │
        │ Examples:          │
        │ Input: "Rick Roll" │
        │ Output: {          │
        │   title: "Never    │
        │   artist: "Rick    │
        │   year: "1987"     │
        │ }                  │
        └────────────────────┘
```

---

## 4. Component Interaction Diagram

```
┌────────────────────┐
│  Frontend/API      │
│  Client            │
└─────────┬──────────┘
          │ POST /api/songs/enhance
          │ {SongMetadataRequest}
          │
          ▼
┌────────────────────────────────────────┐
│  FastAPI Route Handler                 │
│  (app/api/routes/songs.py)             │
│                                        │
│  @router.post("/enhance")              │
│  async def enhance_song(...)           │
└─────────┬──────────────┬───────────────┘
          │              │
          │              ▼
          │        ┌─────────────────────────────┐
          │        │ YT-DLP Service              │
          │        │ (if source="youtube")       │
          │        │                             │
          │        │ _get_video_description()    │
          │        │ ├─ Run: yt-dlp -j -e URL    │
          │        │ ├─ Parse JSON               │
          │        │ ├─ Extract description      │
          │        │ └─ Return (max 500 chars)   │
          │        └─────────┬───────────────────┘
          │                  │
          │                  ▼
          │        (description context)
          │
          ▼
┌────────────────────────────────────────────────┐
│  Enhancement Service                           │
│  (app/services/enhancement_service.py)         │
│                                                │
│  EnhancementService.enhance():                 │
│  1. Build context (title, artist, tags, desc) │
│  2. Call _call_openai()                       │
│  3. Parse response                            │
│  4. Validate fields                           │
│  5. Return enhanced or original               │
└─────────┬──────────────────┬──────────────────┘
          │                  │
          │                  ▼
          │        ┌──────────────────────────┐
          │        │  OpenAI API              │
          │        │  (external service)      │
          │        │                          │
          │        │  Model: gpt-4o-mini      │
          │        │  Temp: 0                 │
          │        │  Timeout: 30s            │
          │        │                          │
          │        │  POST /chat/completions  │
          │        └──────────────┬───────────┘
          │                       │
          │                       ▼
          │                (enhanced fields)
          │
          ▼
┌────────────────────────────────────────────┐
│  Response Handler                          │
│  (back in route handler)                   │
│                                            │
│  1. Merge enhanced fields with original    │
│  2. Build SongMetadataResponse             │
│  3. Pydantic validation                    │
│  4. Return JSON                            │
└─────────┬──────────────────────────────────┘
          │
          ▼
┌────────────────────┐
│  HTTP 200 OK       │
│  {                 │
│    "title": "...", │
│    "artist": "...",│
│    "year": "...",  │
│    ...             │
│  }                 │
└────────────────────┘
```

---

## 5. Data Flow (Single Song Enhancement)

```
Input Data:
┌────────────────────────────────────────────┐
│ videoId: "x_6nob9_WLc"                     │
│ title: "[Karaoke 0] Aqours - 未熟DREAMER..."│
│ artist: ""                                  │
│ year: ""                                    │
│ language: ""                                │
│ tags: ["aqours", "love live", ...]         │
└────────────────────────────────────────────┘
             │
             ▼
        YouTube Description
    (fetched via yt-dlp):
┌────────────────────────────────────────────┐
│ "AQOURS LOVE LIVE SUNSHINE... founded 2014" │
└────────────────────────────────────────────┘
             │
             ▼
        LLM Context:
┌────────────────────────────────────────────┐
│ Title: [Karaoke 0] Aqours - 未熟DREAMER... │
│ Current artist: [empty]                     │
│ Tags: aqours, love live, karaoke...        │
│ Description: AQOURS LOVE LIVE SUNSHINE...  │
│                                             │
│ Examples:                                   │
│ Input: "[Karaoke] Rick - Never Gonna..."   │
│ Output: {                                   │
│   title: "Never Gonna Give You Up",        │
│   artist: "Rick Astley",                   │
│   year: 1987,                              │
│   language: "en"                           │
│ }                                           │
└────────────────────────────────────────────┘
             │
             ▼
        OpenAI API Call
    (gpt-4o-mini, temp=0)
             │
             ▼
        LLM Response:
┌────────────────────────────────────────────┐
│ {                                           │
│   "title": "未熟DREAMER",                   │
│   "artist": "Aqours",                       │
│   "year": 2016,          (NOTE: integer)    │
│   "language": "ja"                          │
│ }                                           │
└────────────────────────────────────────────┘
             │
             ▼
        Parse & Convert to Strings:
┌────────────────────────────────────────────┐
│ title: "未熟DREAMER"                        │
│ artist: "Aqours"                            │
│ year: "2016"             (converted)        │
│ language: "ja"                              │
└────────────────────────────────────────────┘
             │
             ▼
        Validate:
        ├─ title length: ✓ (valid)
        ├─ year range: ✓ (2016 in 1900-2100)
        └─ language: ✓ (ja in SUPPORTED_LANGUAGES)
             │
             ▼
        Merge with Original:
┌────────────────────────────────────────────┐
│ videoId: "x_6nob9_WLc"    (original)       │
│ title: "未熟DREAMER"        (enhanced ✓)    │
│ artist: "Aqours"            (enhanced ✓)    │
│ year: "2016"                (enhanced ✓)    │
│ language: "ja"              (enhanced ✓)    │
│ duration: 352               (original)       │
│ tags: [...]                 (original)       │
│ url: "https://..."          (original)       │
│ thumbnail: "https://..."    (original)       │
│ source: "youtube"           (original)       │
│ lyrics: ""                  (reserved)       │
└────────────────────────────────────────────┘
             │
             ▼
        HTTP 200 OK
    {enhanced song metadata}
```

---

## 6. State Transitions

```
Start: RequestReceived
    │
    ├─→ ValidateSchema ─X→ InvalidSchema ──→ HTTP 400
    │
    ├─→ CheckOpenAIKey ─X→ NoKeyConfigured ──→ ReturnOriginal
    │
    ├─→ FetchDescription (optional) ──→ DescriptionFetched
    │   │                                    │
    │   X──────────────────→ DescriptionFailed (continue anyway)
    │
    ├─→ BuildContext ──→ ContextReady
    │
    ├─→ CallOpenAI ─X→ APIFailed ──→ ReturnOriginal
    │
    ├─→ ParseResponse ─X→ ParseFailed ──→ ReturnOriginal
    │
    ├─→ ValidateFields ──→ FieldsValid
    │                      │
    │                      ├─→ SomeFieldsValid ──→ PartialEnhanced
    │                      │                      │
    │                      X──→ AllFieldsInvalid ──→ ReturnOriginal
    │
    ├─→ MergeResults ──→ ResultReady
    │
    ├─→ SerializeResponse ──→ ResponseReady
    │
    └─→ HTTPResponse (200 OK) ──→ End

Key:
├─→ Success path
X→  Error/failure path
```

---

## 7. Temperature & Determinism

```
Without Temperature Control (default ~0.7):
┌───────────┐
│ Input     │─→ LLM ─→ Random output variation
│ Same      │         (unpredictable)
│ Request   │─→ LLM ─→ Different output each time
│ x3        │─→ LLM ─→ Different output again
└───────────┘

                    ║

With Temperature=0 (B6 Setting):
┌───────────┐
│ Input     │─→ LLM ─→ Deterministic output
│ Same      │         (same every time)
│ Request   │─→ LLM ─→ Identical output
│ x3        │─→ LLM ─→ Identical output
└───────────┘

Rationale:
- Reproducible results (same song always enhances the same way)
- Predictable behavior (no variation surprises)
- Better validation (deterministic fields to validate against)
```

---

## Summary

This is a **simple, direct approach**:
1. ✅ **Single LLM call** (not multi-step agentic reasoning)
2. ✅ **Context building** (combine metadata sources)
3. ✅ **Prompt engineering** (examples guide extraction)
4. ✅ **Deterministic** (temperature=0)
5. ✅ **Validated** (reject invalid responses)
6. ✅ **Graceful degradation** (return original on any error)
7. ✅ **Fast** (~3-5 seconds)
8. ✅ **Cost-effective** (~$0.00008 per song)

See also:
- [B6_ARCHITECTURE.md](B6_ARCHITECTURE.md) - Detailed architecture explanation
- [../apps/singalong-node/app/services/enhancement_service.py](../apps/singalong-node/app/services/enhancement_service.py) - Implementation code
