# Singalong Project Overview

## Project Goal

Build a distributed karaoke system where an admin can setup sessions for occasions, attendees can reserve and sing songs collaboratively, and the system gracefully handles offline access and dynamic song discovery.

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    MASTER SERVER (REST API)                 │
│  • Central source of truth for all songs and metadata       │
│  • Handles YouTube downloads via YT-DLP                    │
│  • Database management and data persistence                 │
│  • Provides APIs for Node(s) to fetch and sync              │
└────────────────────┬─────────────────────────────────────────┘
                     │ (REST API)
                     │
    ┌────────────────▼──────────────────┐
    │  MASTER-WS (WebSocket Service)    │
    │  • Real-time notifications        │
    │  • Download progress streaming    │
    │  • Event broadcasting to Node(s)  │
    └────────────────▲──────────────────┘
                     │ (WebSocket)
                     │
┌──────────────────────────────────────────────────────────────┐
│                    NODE SERVER (REST API)                   │
│  • Intermediary between frontends and master                │
│  • Downloads/caches songs from master for offline access    │
│  • Searches YouTube via YT-DLP                              │
│  • Manages active sessions and user connections             │
│  • Syncs song data and metadata with Master                 │
└────────────────────┬─────────────────────────────────────────┘
                     │ (WebSocket)
                     │
    ┌────────────────▼──────────────────┐
    │   NODE-WS (WebSocket Service)     │
    │  • Real-time session updates      │
    │  • Queue change notifications     │
    │  • User join/leave events         │
    │  • Download progress              │
    └────────────────▲──────────────────┘
                     │ (WebSocket)
          ┌──────────┴──────────┐
          │                     │
    ┌─────────────────┐    ┌──────────────────┐
    │   CONTROLLER    │    │      ADMIN       │
    │  (Attendee UI)  │    │   (Admin UI)     │
    └─────────────────┘    └──────────────────┘
```

**Key Principle**: Frontends ONLY communicate with Node. Master is accessed exclusively through Node. This allows offline-first operation and clean separation of concerns.

---

## User Stories

### Controller (Attendee)

As an attendee, I want to:

1. **Set my nickname** when joining a session
2. **Join a session** through a node with a session code/identifier
3. **View reserved songs** - see what's currently queued to be sung
4. **View songbook** - browse available songs already in the system
5. **Reserve songs** - select a song I want to sing from the songbook
6. **Suggest new songs** - search for songs not in the songbook
   - Option 1: Use built-in search (Node queries YouTube via YT-DLP)
   - Option 2: Search externally and paste a YouTube URL directly
7. **Enhance song details** - review/edit title, artist, lyrics before confirming download
8. **Download & optionally reserve** - initiate download of a suggested song and optionally add to my queue
9. **(Future) Fair queueing** - have a mechanism to take consistent turns with other attendees

### Admin

As an admin, I want to:

1. **Setup a node** - initialize a node and establish connection to master server
2. **Pre-load songs** - the node automatically syncs song data/files from master for offline access
3. **Create a session** - setup a karaoke session with title, vibes/recommendations, etc.
4. **Reserve songs for guests** - add songs to the queue on behalf of guests who don't want to use a phone
5. **Manage song order** - reorder reserved songs to prioritize certain tracks
6. **All Controller features** - as an admin, I can also join as an attendee and use all controller features
7. **Manage connections** - monitor and manage who's connected to the session
8. **Manage session playback** - play/pause/skip songs during the session

### Node (Backend Middleware)

The Node service is responsible for:

1. **Frontend interaction** - expose REST APIs for both controller and admin apps
2. **Master communication** - sync song data and metadata with master server via REST
3. **Song search** - perform YouTube searches using YT-DLP to help attendees find new songs
4. **Local caching** - download and cache songs from master for internet-less operation
5. **Session management** - track active sessions, connections, reservations, and playback state
6. **Song metadata handling** - receive, enhance, and forward song metadata to master for new downloads
7. **Download coordination** - listen to Master-WS for download completion notifications

### Node-WS (WebSocket Service)

A dedicated WebSocket service for Node-to-Frontend real-time communication:

1. **Session updates** - broadcast queue changes, new reservations, song reorders
2. **User events** - notify attendees when users join/leave session
3. **Download progress** - stream download progress for songs being added to songbook
4. **Connection management** - maintain persistent connections with controller and admin frontends

### Master (Central Backend)

The Master server is responsible for:

1. **Node communication** - provide REST APIs for nodes to query, download, and sync songs
2. **Song storage** - maintain the canonical source of truth for all songs and metadata
3. **YouTube integration** - download songs from YouTube using YT-DLP as primary download mechanism
4. **Database management** - persist all song data, metadata, and system state
5. **Data persistence** - handle all permanent data storage and retrieval

### Master-WS (WebSocket Service)

A dedicated WebSocket service for Master-to-Node real-time communication:

1. **Download progress notifications** - stream download progress to Node(s)
2. **Draft song promotions** - notify when a draft song has been successfully downloaded
3. **Event broadcasting** - broadcast significant events to connected Node(s)
4. **Connection management** - maintain persistent connections with Node(s)

---

## Component Responsibilities Summary

| Feature | Controller | Admin | Node | Master |
|---------|-----------|-------|------|--------|
| Set nickname | ✓ | ✓ | - | - |
| Join session | ✓ | - | ✓ | - |
| View reserved songs | ✓ | ✓ | ✓ | - |
| Browse songbook | ✓ | ✓ | ✓ | ✓ |
| Reserve songs | ✓ | ✓ | ✓ | - |
| Search YouTube | ✓ | ✓ | ✓ | - |
| Enhance metadata | ✓ | ✓ | ✓ | - |
| Download songs | ✓ | ✓ | ✓ | ✓ |
| Setup node | - | ✓ | ✓ | ✓ |
| Pre-load songs | - | - | ✓ | ✓ |
| Create session | - | ✓ | ✓ | - |
| Manage users | - | ✓ | ✓ | - |
| Playback control | - | ✓ | ✓ | - |

---

## Detailed Flow: Adding a New Song (Attendee Workflow)

### Scenario: Attendee wants to sing a song not in the current songbook

**Actors**: Attendee (Controller), Node, Master, YT-DLP

**Steps**:

1. **Controller**: Attendee opens controller app, connects to session
2. **Controller**: Attendee browses songbook, doesn't find the desired song
3. **Controller**: Attendee initiates song search (either built-in or manual URL paste)
   
   **Path A - Built-in Search**:
   - Controller sends search query to Node (e.g., "Bohemian Rhapsody karaoke")
   - Node uses YT-DLP to query YouTube for matches
   - YT-DLP returns list of candidates
   - Node sends results back to Controller
   - Attendee selects a video from the list

   **Path B - Manual URL**:
   - Attendee finds video on YouTube externally
   - Attendee copies video URL
   - Attendee pastes URL into Controller
   - Controller sends URL to Node
   - Node validates the URL (YT-DLP can parse it)

4. **Node**: Receives attendee's final selection (video URL)
5. **Node**: Fetches additional metadata from YouTube via YT-DLP
6. **Controller**: Displays song details to attendee (title, artist, duration, thumbnail, etc.)
7. **Controller**: Attendee can manually enhance details if needed (correct title, add artist, etc.)
8. **Controller**: Attendee confirms and sends enhanced metadata + video URL back to Node
9. **Node**: Forwards the metadata and URL to Master server with a "create draft song" request
10. **Master**: Receives request, creates a draft entry, starts downloading video from YouTube using YT-DLP
11. **Master**: After download succeeds, stores the song file and metadata
12. **Master**: Notifies Node that download completed (via webhook, WebSocket, or polling)
13. **Node**: Receives notification, downloads a copy of the song file and metadata from Master
14. **Node**: Updates its local songbook cache
15. **Node**: Optionally reserves the song for the attendee if they requested it
16. **Controller**: Notifies attendee that song download succeeded and songbook is updated
17. **Controller**: Song appears in available songbook and/or attendee's reserved queue

---

## Session Flow: A Complete Karaoke Session

### Setup Phase

1. Admin initializes a node connection to master
2. Node syncs all available songs from master to local cache
3. Admin creates a session (title, vibes, etc.)
4. Node creates a session record and waits for attendees

### Join Phase

1. Attendees join the session using controller app
2. Each attendee sets their nickname
3. Node tracks all connected users
4. Admin can see all connected users in admin dashboard

### Reservation Phase

1. Attendees browse songbook and reserve songs
2. Admin can also manually reserve songs for guests
3. Admin can reorder the reservation queue
4. Node maintains the queue state

### Song Discovery Phase (Optional)

1. If an attendee wants a song not in the songbook, they initiate search
2. Process follows "Adding a New Song" flow above
3. Once downloaded, song becomes available to all in that session

### Playback Phase

1. Admin initiates playback
2. Songs are played in queue order from the reservation list
3. Admin can pause, skip, or reorder during playback
4. (Future) Fair queueing ensures each attendee gets consistent turns

### Teardown Phase

1. Session ends
2. Node closes all connections
3. Session data can be archived (songs sung, attendees, etc.)

---

## Key Design Decisions

1. **Offline-First**: Nodes cache songs locally so sessions can proceed without internet connectivity
2. **Two-Tier Architecture**: Master as source of truth, Nodes as local proxies enables scalability and resilience
3. **No Direct Master Access from Frontends**: Simplifies frontend logic, centralizes session management in Node
4. **Dynamic Song Discovery**: Users can extend the songbook with YouTube videos in real-time
5. **Metadata Enhancement**: Users can correct/enhance song details before they're permanently stored

---

## Future Enhancements (Out of Scope for Now)

- Fair queueing system for consistent turn-taking
- Song ratings and recommendations
- Lyrics display during singing
- Audio/video playback integration
- Scoring and leaderboards
- Multi-node federation for large events
- Song synchronization across multiple sessions

---

## Status: Complete

This document captures the complete understanding of the system's goals and responsibilities.
