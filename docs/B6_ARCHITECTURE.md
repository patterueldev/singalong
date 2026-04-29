# B6 Song Enhancement Architecture & Implementation

**Version**: 1.0  
**Status**: Production  
**Last Updated**: 2026-04-29

---

## Executive Summary

B6 uses **direct LLM API calls** (OpenAI gpt-4o-mini) for metadata enhancement, NOT orchestration or agents. The enhancement is:

- **Fast**: ~3-5 seconds per song (single LLM call)
- **Simple**: Direct context + prompt engineering (no multi-step agentic reasoning)
- **Deterministic**: Temperature=0 (reproducible results)
- **Graceful**: Degrades to original metadata on any error
- **No external research**: Works from existing metadata context only

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User/Frontend                             │
│                  Calls /api/songs/enhance                   │
└────────────────────┬────────────────────────────────────────┘
                     │ POST {song metadata}
                     ▼
        ┌────────────────────────────────────────┐
        │  FastAPI Route Handler                  │
        │  /api/songs/enhance                     │
        │                                         │
        │ 1. Validate request schema              │
        │ 2. Check OpenAI key configured         │
        │ 3. If YouTube: fetch description       │
        │ 4. Call EnhancementService.enhance()  │
        │ 5. Return result (200 OK always)       │
        └────────────────┬────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────┐
        │  EnhancementService.enhance()           │
        │  (No agents, no orchestration)          │
        │                                         │
        │ Step 1: Build Context                  │
        │  ├─ Extract: title, artist, year,      │
        │  │           language, tags, duration  │
        │  └─ Fetch: YouTube description         │
        │                                         │
        │ Step 2: Call OpenAI (single call)      │
        │  ├─ Model: gpt-4o-mini                 │
        │  ├─ Temperature: 0 (deterministic)    │
        │  ├─ Timeout: 30 seconds                │
        │  └─ Prompt: structured extraction     │
        │                                         │
        │ Step 3: Parse Response                 │
        │  ├─ Extract JSON from response        │
        │  ├─ Convert to strings                │
        │  └─ Validate (year range, lang codes) │
        │                                         │
        │ Step 4: Return Enhanced or Original   │
        │  ├─ On success: return enhanced       │
        │  └─ On error: return original         │
        │     (graceful degradation)             │
        └────────────────┬────────────────────────┘
                         │ Returns dict
                         ▼
        ┌────────────────────────────────────────┐
        │  Response Validation (Pydantic)         │
        │  Serialize to SongMetadataResponse     │
        └────────────────┬────────────────────────┘
                         │ JSON response
                         ▼
        ┌────────────────────────────────────────┐
        │             HTTP 200 OK                 │
        │         {enhanced metadata}             │
        └────────────────────────────────────────┘
```

---

## NOT Using Agents / Orchestration

### Why NOT Multi-Agent?

Current B6 is **single-step, deterministic extraction** — not iterative reasoning. Multi-agent approaches would be:

- **Slower**: Multiple API calls and reasoning loops
- **Expensive**: More tokens per enhancement
- **Unnecessary**: We don't need agents for simple extraction
- **Harder to debug**: Harder to trace failures across agents

### Current Approach: Prompt Engineering + Context

Instead of agents, we use:

1. **Rich Context Building**
   - Combine title + artist + year + language + tags + description
   - Provide examples in prompt (in-context learning)
   - Let LLM extract cleanly based on context

2. **Structured Prompts**
   - Clear instructions for each field
   - Examples of expected outputs
   - Validation rules in prompt itself

3. **Post-Processing**
   - Validate LLM response (year range, language codes)
   - Reject invalid responses gracefully
   - Fall back to original on any error

---

## NOT Researching from Internet

B6 does **NOT** search the internet or use external APIs. Instead:

### What B6 Does
1. **Extracts from existing metadata**
   - YouTube title, description, tags
   - Video duration
   - Language hints from metadata

2. **Uses LLM's training knowledge**
   - gpt-4o-mini knows most songs
   - Can extract release years from training data
   - Can identify languages/artists from context

### What B6 Does NOT Do
- ❌ Call Genius API for lyrics
- ❌ Call Spotify API for release date
- ❌ Scrape Wikipedia for artist info
- ❌ Make HTTP requests to external services
- ❌ Parse HTML from music databases

### Why No External Research?

**Speed**: Single API call (~3-5 seconds) vs multiple external lookups (~10-30 seconds)

**Cost**: No additional API costs beyond OpenAI

**Reliability**: No dependency on external services being available

**Privacy**: Don't leak user data to third-party APIs

**Simplicity**: Prompt engineering > multi-service orchestration

---

## Enhancement Pipeline

### Context Building

Input metadata combined with YouTube description (if available):

```
Title: [Karaoke 0] Aqours - 未熟DREAMER ( Mijuku DREAMER )
Current Artist: 
Current Year: 
Current Language: 
Duration: 352 seconds
Description: AQOURS LOVE LIVE SUNSHINE...
Tags: aqours, love live, karaoke, instrumental, ...
```

### LLM Call

Single OpenAI gpt-4o-mini call with:
- Temperature: 0 (deterministic)
- Prompt: Structured extraction instructions with examples
- Timeout: 30 seconds

### Response Validation

```
Validation Rules:
- Title: max 200 chars
- Year: 1900-2100 range
- Language: 2-5 char ISO code from SUPPORTED_LANGUAGES
- All fields: never None (use empty string instead)
```

### Output

Merged result with enhanced fields:

```json
{
  "title": "未熟DREAMER",        // ← IMPROVED
  "artist": "Aqours",             // ← IMPROVED
  "year": "2016",                 // ← IMPROVED
  "language": "ja",               // ← IMPROVED
  // ... other fields unchanged
}
```

---

## Cost Analysis

### Per Enhancement

- Input tokens: ~250 (@$0.00015/1K)
- Output tokens: ~75 (@$0.0006/1K)
- **Cost per song**: ~$0.00008

### At Scale

- 1,000 enhancements: ~$0.08
- 10,000 enhancements: ~$0.80
- 100,000 enhancements: ~$8.00

Much cheaper than gpt-4 at $0.003-0.006 per enhancement.

---

## Summary

✅ **Single LLM API call** (no agents, no orchestration)  
✅ **Prompt engineering** (in-context examples guide extraction)  
✅ **Context building** (combine metadata sources)  
✅ **Validation** (reject invalid responses)  
✅ **Graceful degradation** (return original on any error)  
✅ **No external research** (uses LLM training + provided context)  
✅ **Fast** (~3-5 seconds)  
✅ **Cheap** (~$0.00008 per enhancement)  

Perfect for extracting and cleaning metadata from known sources.

See also:
- [B6_FLOWCHARTS_AND_DIAGRAMS.md](B6_FLOWCHARTS_AND_DIAGRAMS.md) - Visual flowcharts and component diagrams
- [../apps/singalong-node/app/services/enhancement_service.py](../apps/singalong-node/app/services/enhancement_service.py) - Implementation code
