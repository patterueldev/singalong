# Singalong Controller - Developer Guide

Frontend web application for users to browse songs, reserve karaoke songs, and participate in singing sessions.

## Quick Links

- **[Root AGENTS.md](../../AGENTS.md)** - Main codebase documentation
- **[Architecture](../../docs/PROJECT_OVERVIEW.md)** - System design
- **[Implementation Phases](../../docs/IMPLEMENTATION_PHASES.md)** - Project roadmap

---

## 1. Project Overview

**Application**: singalong-controller  
**Role**: User-facing karaoke interface  
**Type**: Frontend (React + TypeScript)  
**Technology**: React 19.2.5+, TypeScript, Vite, Axios, React Router  
**Port**: 3002 (development)

### Key Responsibilities

1. **Session Join**
   - Enter session code
   - Set user nickname
   - Join active karaoke session

2. **Song Discovery**
   - Browse available songs from songbook
   - Search songs by title or artist
   - View song details (duration, artist, etc.)
   - Filter by genre or other criteria

3. **Song Reservation**
   - Reserve songs to sing
   - View reserved songs queue
   - Optionally search YouTube for songs not in library

4. **Song Suggestion** (Future)
   - Search external YouTube for songs
   - Provide song URLs
   - Review identified metadata
   - Enhance song details (artist, title)
   - Submit for download

5. **Queue Management**
   - View all reserved songs
   - See your position in queue
   - Track which users reserved which songs

---

## 2. Project Structure

```
singalong-controller/
├── src/
│   ├── main.tsx                # React entry point
│   ├── App.tsx                 # Root component & router
│   ├── index.css               # Global styles (dark mode only)
│   ├── pages/                  # Page-level components (routes)
│   │   ├── SessionJoin.tsx     # Session code + nickname entry
│   │   ├── SongBook.tsx        # Browse available songs
│   │   ├── SearchSongs.tsx     # Search within songbook
│   │   ├── Queue.tsx           # View reservation queue
│   │   ├── SearchYouTube.tsx   # External song search
│   │   ├── SongDetail.tsx      # Single song view
│   │   ├── Home.tsx            # Landing page
│   │   └── NotFound.tsx        # 404 page
│   ├── components/             # Reusable UI components
│   │   ├── Header.tsx          # Top navigation
│   │   ├── Navigation.tsx      # Bottom/side navigation
│   │   ├── cards/
│   │   │   ├── SongCard.tsx    # Song card with reserve button
│   │   │   └── QueueCard.tsx   # Queue item
│   │   ├── modals/
│   │   │   ├── JoinSessionModal.tsx
│   │   │   ├── IdentifyModal.tsx  # YouTube URL identification
│   │   │   └── EnhanceModal.tsx   # Metadata enhancement
│   │   └── forms/
│   │       ├── SearchForm.tsx
│   │       └── NicknameForm.tsx
│   ├── hooks/                  # Custom React hooks
│   │   ├── useApi.ts           # Wrapper around axios
│   │   ├── useSession.ts       # Session context hook
│   │   ├── useSongs.ts         # Song fetching & caching
│   │   └── useQueue.ts         # Queue data hook
│   ├── services/               # API client functions
│   │   ├── api.ts              # Axios instance & config
│   │   ├── sessionService.ts   # Session API calls
│   │   ├── songService.ts      # Song API calls
│   │   ├── searchService.ts    # Search API calls (B4)
│   │   ├── identifyService.ts  # Identify API calls (B5)
│   │   ├── enhanceService.ts   # Enhance API calls (B6)
│   │   └── suggestService.ts   # Suggest API calls (B7)
│   ├── types/                  # TypeScript interfaces
│   │   └── index.ts
│   ├── context/                # React Context (state)
│   │   └── SessionContext.tsx
│   └── styles/                 # Component styles
│       └── components.css
├── index.html                  # HTML entry template
├── vite.config.ts              # Vite configuration
├── tsconfig.json               # TypeScript configuration
├── package.json                # Yarn dependencies
├── eslint.config.js            # ESLint rules
├── .env.development            # Dev environment variables
└── README.md                   # App documentation
```

---

## 3. Design Principles

### 3.1 React Best Practices (Same as Admin)

1. **Functional Components Only**
   - Use const Component = () => syntax
   - Use hooks for state and effects

2. **Prop Drilling Prevention**
   - Use Context API for session state
   - Custom hooks access context
   - Avoid passing props through multiple levels

3. **Separation of Concerns**
   - Pages: route-level components
   - Components: reusable UI elements
   - Hooks: stateful logic
   - Services: API communication

4. **Type Safety**
   - All React components strongly typed
   - Define types in types/index.ts

5. **Error Handling**
   - Display user-friendly error messages
   - Handle network timeouts gracefully
   - Log errors for debugging

### 3.2 User Experience Focus

1. **Clear Navigation**
   - Obvious way to join session
   - Easy song browsing
   - Quick reserve action

2. **Feedback**
   - Show loading states
   - Display success/error messages
   - Indicate queue position

3. **Offline Handling** (Future)
   - Show when disconnected
   - Queue requests locally
   - Sync on reconnect

---

## 4. Key Workflows

### 4.1 Join Session Flow

```
User starts app
    ↓
Home page prompts for session code
    ↓ (enters code + nickname)
User clicks Join
    ↓
API call: POST /api/auth (to Node)
    ↓ (returns session token)
Store token in localStorage
    ↓
Redirect to SongBook
    ↓
Auto-fetch songs for this session
```

**Components**:
- `pages/Home.tsx` - Landing page
- `pages/SessionJoin.tsx` - Code + nickname form
- `context/SessionContext.tsx` - Store session state

**Services**:
- `sessionService.ts` - Join session API call

### 4.2 Browse & Reserve Song

```
User on SongBook page
    ↓
Auto-load available songs (GET /api/songs)
    ↓
Display as cards with Reserve button
    ↓ (user clicks reserve)
Show reserve confirmation
    ↓
API call: POST /api/reservations
    ↓
Update local queue state
    ↓
Show success message
```

**Components**:
- `pages/SongBook.tsx` - Main song listing
- `components/cards/SongCard.tsx` - Individual song
- `pages/Queue.tsx` - User's reservations

**Services**:
- `songService.ts` - Fetch songs
- `songService.ts` - Reserve song

### 4.3 Search YouTube (Future - B4-B7)

```
User needs song not in library
    ↓
Open SearchYouTube component
    ↓
Enter keywords or paste YouTube URL
    ↓
Click Search
    ↓
API call: POST /api/search (keywords)
        or POST /api/identify (URL)
    ↓
Display results with identify metadata
    ↓
User selects song
    ↓
Click Enhance (optional)
    ↓
API call: POST /api/enhance
    ↓
Review enhanced metadata
    ↓
Click Suggest
    ↓
API call: POST /api/suggest (with reserve option)
    ↓
Master starts download, Node syncs
    ↓
Song appears in songbook
```

**Components**:
- `pages/SearchYouTube.tsx` - Search UI
- `components/modals/IdentifyModal.tsx` - Metadata display
- `components/modals/EnhanceModal.tsx` - Metadata improvement

**Services**:
- `searchService.ts` - B4 search endpoint
- `identifyService.ts` - B5 identify endpoint
- `enhanceService.ts` - B6 enhance endpoint
- `suggestService.ts` - B7 suggest endpoint

---

## 5. Development Workflow

### 5.1 Setup

```bash
cd apps/singalong-controller

# Install dependencies
yarn install

# Start dev server (Vite with HMR)
yarn dev

# Open in browser
open http://localhost:3002
```

### 5.2 Environment Variables

Create `.env.development`:
```env
VITE_API_BASE_URL=http://localhost:5002
```

### 5.3 Hot Reload (HMR)

Hot reload is configured to work in Docker with polling:
- Changes detected automatically
- Page refreshes on save
- WebSocket HMR protocol configured
- File watching via polling (WATCHPACK_POLLING=true)

### 5.4 TypeScript Checking

```bash
# Type check without building
yarn type-check

# ESLint check
yarn lint

# Fix formatting
yarn lint --fix
```

### 5.5 Build for Production

```bash
yarn build

# Preview production build
yarn preview
```

---

## 6. Key Features Implementation

### 6.1 Axios Configuration

**File**: `src/services/api.ts`

All API requests go through Node (port 5002), never directly to Master.

```typescript
import type { AxiosError } from 'axios';
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:5002',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add session token to all requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('session_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 errors (session expired)
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('session_token');
      window.location.href = '/join';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### 6.2 SongBook Component

**File**: `src/pages/SongBook.tsx`

```typescript
import React, { useEffect, useState } from 'react';
import SongCard from '../components/cards/SongCard';
import type { Song } from '../types';

const SongBook: React.FC = () => {
  const [songs, setSongs] = useState<Song[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchSongs = async () => {
      setLoading(true);
      try {
        const response = await api.get('/api/songs');
        setSongs(response.data);
      } catch (err) {
        setError('Failed to load songs');
      } finally {
        setLoading(false);
      }
    };

    fetchSongs();
  }, []);

  if (loading) return <div>Loading songs...</div>;
  if (error) return <div className="error">{error}</div>;
  if (!Array.isArray(songs)) return <div>No songs available</div>;

  return (
    <div style={{ padding: '20px' }}>
      <h1>Song Book</h1>
      <div style={{ display: 'grid', gap: '10px' }}>
        {songs.map(song => (
          <SongCard key={song.id} {...song} />
        ))}
      </div>
    </div>
  );
};

export default SongBook;
```

### 6.3 Session Context

**File**: `src/context/SessionContext.tsx`

```typescript
import React from 'react';
import type { Session, User } from '../types';

interface SessionContextType {
  session: Session | null;
  user: User | null;
  joinSession: (code: string, nickname: string) => Promise<void>;
  leaveSession: () => void;
}

const SessionContext = React.createContext<SessionContextType | null>(null);

export function useSession() {
  const context = React.useContext(SessionContext);
  if (!context) {
    throw new Error('useSession must be used within SessionProvider');
  }
  return context;
}

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = React.useState<Session | null>(null);
  const [user, setUser] = React.useState<User | null>(null);

  const joinSession = async (code: string, nickname: string) => {
    // API call to Node
    const data = await api.post('/api/auth', { nickname });
    setUser(data.user);
    localStorage.setItem('session_token', data.session_token);
    // Fetch session details
    const sessionData = await api.get(`/api/sessions/${code}`);
    setSession(sessionData);
  };

  const leaveSession = () => {
    setSession(null);
    setUser(null);
    localStorage.removeItem('session_token');
  };

  return (
    <SessionContext.Provider value={{ session, user, joinSession, leaveSession }}>
      {children}
    </SessionContext.Provider>
  );
}
```

---

## 7. Styling

### 7.1 Dark Mode Only

The app enforces dark mode globally via `src/index.css`:

```css
color-scheme: dark;
:root {
  --bg: #16171d;
  --text: #9ca3af;
  --accent: #c084fc;
}

body {
  background: var(--bg);
  color: var(--text);
}
```

No light mode. Light mode preference in OS/browser is ignored.

### 7.2 Component Styling

Use inline styles or CSS modules (not external framework):

```typescript
const containerStyle = {
  padding: '20px',
  maxWidth: '1200px',
  margin: '0 auto',
};

return <div style={containerStyle}>...</div>;
```

---

## 8. Testing

### 8.1 Test API Connectivity

```bash
# From browser console or terminal
curl http://localhost:5002/health
```

### 8.2 Test Session Join

1. Open http://localhost:3002
2. Enter session code (from Admin)
3. Enter nickname
4. Click Join
5. Should redirect to SongBook

### 8.3 Test Song Reservation

1. On SongBook, click "Reserve" on any song
2. Check Network tab (DevTools) for POST to /api/reservations
3. Should show success message
4. Should appear in Queue page

---

## 9. Common Tasks

### Check TypeScript Errors

```bash
yarn type-check
```

### Run ESLint

```bash
yarn lint
```

### Debug in Browser

1. Open http://localhost:3002
2. Press F12 (DevTools)
3. Check Console, Network tabs
4. Use React DevTools extension

### View All Logs

Browser console shows:
- API calls (Network tab)
- Component renders (React DevTools)
- Errors (Console tab)

---

## 10. Key Files Reference

| File | Purpose |
|------|---------|
| `src/main.tsx` | React entry point |
| `src/App.tsx` | Root component and routing |
| `src/services/api.ts` | Axios configuration |
| `src/services/*.ts` | API service functions |
| `src/hooks/*.ts` | Custom React hooks |
| `src/pages/*.tsx` | Full-page components |
| `src/components/*.tsx` | Reusable UI components |
| `src/context/*.tsx` | React Context for state |
| `src/types/index.ts` | TypeScript interfaces |
| `vite.config.ts` | Build configuration (HMR, watch) |
| `.env.development` | Dev environment variables |

---

## 11. API Endpoints Used

All endpoints are on Node (port 5002):

**Session**:
- `POST /api/auth` - Join with nickname
- `GET /api/sessions/{code}` - Get session details

**Songs**:
- `GET /api/songs` - List available songs
- `POST /api/search` - Search YouTube (B4)
- `POST /api/identify` - Extract metadata (B5)
- `POST /api/enhance` - Improve metadata (B6)

**Reservations**:
- `POST /api/reservations` - Reserve a song
- `GET /api/sessions/{code}/reservations` - List queue

**Suggestions** (Future):
- `POST /api/suggest` - Submit new song (B7)

---

## Document Version

- **Created**: 2026-04
- **Version**: 1.0.0
- **Status**: Active
