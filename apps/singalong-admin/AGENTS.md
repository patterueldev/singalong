# Singalong Admin - Developer Guide

Frontend web application for administrators to manage sessions, view connected users, manage the song queue, and configure the karaoke system.

## Quick Links

- **[Root AGENTS.md](../../AGENTS.md)** - Main codebase documentation
- **[Architecture](../../docs/PROJECT_OVERVIEW.md)** - System design
- **[Implementation Phases](../../docs/IMPLEMENTATION_PHASES.md)** - Project roadmap
- **[Admin UI Specification](../../docs/ADMIN_UI_SPECIFICATION.md)** - UI layout, panels, and components
- **[Sessions Architecture](../../docs/SESSIONS_ARCHITECTURE.md)** - Session management backend design

---

## 1. Project Overview

**Application**: singalong-admin  
**Role**: Admin dashboard and session management UI  
**Type**: Frontend (React + TypeScript)  
**Technology**: React 19.2.5+, TypeScript, Vite, Axios, React Router  
**Port**: 3001 (development)

### Key Responsibilities

1. **Session Management**
   - Create and configure karaoke sessions
   - Set session title and mood/vibes
   - Manage session lifecycle (start, pause, stop)

2. **User Management**
   - View connected users
   - Remove users if needed
   - Manage user permissions

3. **Queue Management**
   - View song reservations queue
   - Reorder songs by priority
   - Skip or remove songs from queue

4. **Song Management**
   - Browse available song library
   - Reserve songs for guests
   - Search and filter songs

5. **System Monitoring**
   - View session status
   - Monitor connection health
   - View activity logs

---

## 2. Project Structure

```
singalong-admin/
├── src/
│   ├── main.tsx                # React entry point
│   ├── App.tsx                 # Root component & router
│   ├── index.css               # Global styles (dark mode only)
│   ├── pages/                  # Page-level components (routes)
│   │   ├── Dashboard.tsx       # Main admin dashboard
│   │   ├── Sessions.tsx        # Session list & creation
│   │   ├── SessionDetail.tsx   # Active session management
│   │   ├── SongBook.tsx        # Song library browser
│   │   ├── Queue.tsx           # Song queue manager
│   │   ├── Users.tsx           # Connected users view
│   │   └── NotFound.tsx        # 404 page
│   ├── components/             # Reusable UI components
│   │   ├── Header.tsx          # Top navigation
│   │   ├── Navigation.tsx      # Sidebar navigation
│   │   ├── cards/
│   │   │   ├── SessionCard.tsx
│   │   │   ├── SongCard.tsx
│   │   │   └── UserCard.tsx
│   │   └── modals/
│   │       ├── CreateSessionModal.tsx
│   │       └── ReserveSongModal.tsx
│   ├── hooks/                  # Custom React hooks
│   │   ├── useApi.ts           # Wrapper around axios
│   │   ├── useSession.ts       # Session context hook
│   │   ├── useSongs.ts         # Song fetching & caching
│   │   └── useAuth.ts          # User authentication
│   ├── services/               # API client functions
│   │   ├── api.ts              # Axios instance & config
│   │   ├── sessionService.ts   # Session API calls
│   │   ├── songService.ts      # Song API calls
│   │   ├── userService.ts      # User API calls
│   │   └── reservationService.ts
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

### 3.1 React Best Practices

1. **Functional Components Only**
   - Use const Component = () => syntax
   - Use hooks for state and effects

2. **Prop Drilling Prevention**
   - Use Context API for global state (session, user)
   - Use custom hooks to access context
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
   - Wrap page components in Error Boundary
   - Display user-friendly error messages
   - Log errors for debugging

### 3.2 SOLID Principles in React

1. **Single Responsibility**: Each component has one purpose
2. **Open/Closed**: Components extend behavior via props/context
3. **Liskov Substitution**: Custom hooks are interchangeable
4. **Interface Segregation**: Components accept only needed props
5. **Dependency Inversion**: Components depend on services, not implementations

---

## 4. Key Patterns

### 4.1 Custom Hooks Pattern

Extract stateful logic into reusable hooks:

```typescript
// src/hooks/useSongs.ts
function useSongs(limit?: number) {
  const [songs, setSongs] = React.useState([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  
  React.useEffect(() => {
    setLoading(true);
    songService.getSongs(limit)
      .then(setSongs)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, [limit]);
  
  return { songs, loading, error };
}

// Usage in component
function SongBook() {
  const { songs, loading, error } = useSongs(100);
  
  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!Array.isArray(songs)) return <div>No songs</div>;
  
  return songs.map(song => <SongCard key={song.id} {...song} />);
}
```

### 4.2 API Service Pattern

```typescript
// src/services/songService.ts
export async function getSongs(limit: number = 100, offset: number = 0) {
  const response = await api.get('/songs', {
    params: { limit, offset }
  });
  return response.data;
}

export async function reserveSong(songId: string, sessionId: string) {
  const response = await api.post('/reservations', {
    songId,
    sessionId
  });
  return response.data;
}
```

### 4.3 Context for Global State

```typescript
// src/context/SessionContext.tsx
interface SessionContextType {
  sessionId: string | null;
  session: Session | null;
  joinSession: (code: string) => Promise<void>;
  leaveSession: () => void;
}

const SessionContext = React.createContext<SessionContextType | null>(null);

export function useSession() {
  const context = React.useContext(SessionContext);
  if (!context) throw new Error('useSession outside provider');
  return context;
}

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = React.useState<Session | null>(null);
  
  const joinSession = async (code: string) => {
    const data = await sessionService.join(code);
    setSession(data);
  };
  
  return (
    <SessionContext.Provider value={{ sessionId: session?.id || null, session, joinSession, leaveSession }}>
      {children}
    </SessionContext.Provider>
  );
}
```

---

## 5. Development Workflow

### 5.1 Setup

```bash
cd apps/singalong-admin

# Install dependencies
yarn install

# Start dev server (Vite with HMR)
yarn dev

# Open in browser
open http://localhost:3001
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

## 6. API Integration

### 6.1 Axios Configuration

**File**: `src/services/api.ts`

All API requests go through Node (port 5002), never directly to Master.

```typescript
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
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('session_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### 6.2 API Response Error Handling

Always check for errors:

```typescript
try {
  const data = await api.get('/songs');
  setSongs(data.data);
} catch (error) {
  if (error.response?.status === 404) {
    setError('Songs not found');
  } else {
    setError('Failed to load songs');
  }
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

No light mode colors are defined. Light mode preference in OS/browser is ignored.

### 7.2 Component Styles

Use CSS modules or inline styles (not a separate CSS framework):

```typescript
// src/pages/SongBook.tsx
const SongBook = () => {
  return (
    <div style={{ padding: '20px' }}>
      <h1>Song Book</h1>
      <div style={{ display: 'grid', gap: '10px' }}>
        {/* songs */}
      </div>
    </div>
  );
};
```

---

## 8. Common Tasks

### Check for TypeScript Errors

```bash
yarn type-check
```

### Run ESLint

```bash
yarn lint
```

### Test API Connectivity

```bash
curl http://localhost:5002/health
```

### Debug in Browser

1. Open http://localhost:3001
2. Press F12 (DevTools)
3. Use Console, Network, and Sources tabs

### Test Component in Isolation

Create a story file (future component tests):
```typescript
// src/components/SongCard.stories.tsx
import SongCard from './SongCard';

export default {
  component: SongCard,
  title: 'Cards/SongCard',
};

export const Example = {
  args: {
    id: '1',
    title: 'Song Title',
    artist: 'Artist Name',
    onReserve: () => {},
  },
};
```

---

## 9. Key Files Reference

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

## 10. Performance Tips

1. **Use custom hooks to avoid re-renders**
   - Memoize expensive calculations
   - Use useCallback for event handlers

2. **Lazy load pages**
   ```typescript
   const SongBook = lazy(() => import('./pages/SongBook'));
   
   <Suspense fallback={<Loading />}>
     <SongBook />
   </Suspense>
   ```

3. **Optimize list rendering**
   ```typescript
   {songs.map(song => (
     <SongCard key={song.id} {...song} />  // Always use stable key
   ))}
   ```

---

## 11. Browser DevTools

### Redux DevTools (if using Redux)
- Available in browser extension

### React DevTools
- Inspect component tree
- Check props and state
- Profile component renders

### Network Tab
- Monitor API calls to Node
- Check response status and headers
- Debug timeout issues

---

## Document Version

- **Created**: 2026-04
- **Version**: 1.0.0
- **Status**: Active
