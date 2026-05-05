# Singalong Controller

A modern React + TypeScript + Vite frontend application for the Singalong service. This app allows users to explore the song book, reserve songs, search for songs, and make song suggestions.

## Features

- **Song Book Explorer**: Browse and explore the complete song library
- **Song Reservation**: Reserve songs for upcoming performances
- **Song Search**: Powerful search functionality to find songs by title, artist, genre, and more
- **Song Suggestions**: Submit suggestions for new songs to add to the collection
- **Real-time Updates**: Hot Module Replacement (HMR) for instant development feedback

## Tech Stack

- **React 19**: Modern UI library with hooks
- **TypeScript**: Type-safe development
- **Vite**: Lightning-fast build tool and dev server
- **React Router**: Client-side routing
- **Axios**: HTTP client with interceptors

## Project Structure

```
src/
├── components/      # Reusable React components
├── pages/          # Page-level components (routed)
├── hooks/          # Custom React hooks (e.g., useApi)
├── services/       # API client and service utilities
├── App.tsx         # Main app component with routing
├── main.tsx        # Application entry point
└── App.css         # Global styles
```

## Getting Started

### Prerequisites

- Node.js 16+ or yarn
- Yarn package manager

### Installation

```bash
cd singalong-controller
yarn install
```

### Development

Start the development server:

```bash
yarn dev
```

The app will be available at `http://localhost:3002` with HMR enabled.

### Environment Variables

Create `.env.development` or `.env.production` files:

```env
VITE_API_BASE_URL=http://localhost:3001    # Backend API URL
VITE_APP_TITLE=Singalong Controller         # App title
```

Default values are configured in `.env`.

### Build

Build for production:

```bash
yarn build
```

Preview the production build:

```bash
yarn preview
```

### Linting

Run ESLint to check code quality:

```bash
yarn lint
```

## Available Scripts

- `yarn dev` - Start development server (port 3002)
- `yarn build` - Build for production
- `yarn preview` - Preview production build locally
- `yarn lint` - Run ESLint to check code quality

## API Integration

The app uses Axios with a preconfigured client in `src/services/api.ts`. Custom hook `useApi` in `src/hooks/useApi.ts` handles API requests with loading and error states.

Example usage:

```typescript
import { useApi } from '../hooks/useApi';

function SongList() {
  const { data: songs, loading, error, request } = useApi();

  useEffect(() => {
    request('get', '/api/songs');
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error loading songs</p>;
  return <div>{/* render songs */}</div>;
}
```

## Development Notes

- HMR is configured for port 3002
- API base URL defaults to `http://localhost:3001`
- Environment-specific configuration uses `.env.development` and `.env.production`
- TypeScript strict mode is enabled for safer development

## Future Enhancements

- Add state management (Redux, Zustand, or Jotai)
- Add component testing (Vitest + React Testing Library)
- Add E2E testing (Playwright or Cypress)
- Add UI component library (shadcn/ui, Ant Design, etc.)
- Add form validation (Zod, Yup)

