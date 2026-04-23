# Singalong Admin

A Vite + React + TypeScript frontend application for managing the Singalong node. This service provides node management capabilities, establishes a local development server, and exposes most of the controller's functionality for exploring and reserving songs.

## Features

- 🎵 Song exploration and discovery
- 📋 Song reservation management
- 🎛️ Node management and configuration
- ⚡ Hot Module Replacement (HMR) in development
- 🔌 API integration with the Singalong node server
- 📱 Responsive UI with React Router

## Tech Stack

- **Frontend Framework**: React 19
- **Build Tool**: Vite
- **Language**: TypeScript
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Package Manager**: Yarn

## Prerequisites

- Node.js 16+ and Yarn
- Running Singalong node server (default: `http://localhost:3000`)

## Installation

1. Install dependencies:

```bash
yarn install
```

2. Configure environment variables:

```bash
cp .env.example .env.local
```

Then edit `.env.local` to set your node server URL if different from the default.

## Development

Start the development server:

```bash
yarn dev
```

The app will be available at `http://localhost:3001` with HMR enabled.

## Building

Build for production:

```bash
yarn build
```

Preview the production build:

```bash
yarn preview
```

## Type Checking

Check TypeScript types:

```bash
yarn type-check
```

## Linting

Run ESLint:

```bash
yarn lint
```

## Project Structure

```
src/
├── components/      # Reusable UI components
├── pages/          # Page components for routes
├── hooks/          # Custom React hooks
├── services/       # API services and HTTP client
├── config/         # Configuration files
├── assets/         # Static assets
├── App.tsx         # Root app component
└── main.tsx        # Application entry point
```

## Environment Variables

Create a `.env.local` file (see `.env.example`):

- `VITE_NODE_URL` - The URL of the Singalong node server (default: `http://localhost:3000`)

## API Integration

The app uses Axios for API calls. Configure your node server URL in `.env.local`:

```
VITE_NODE_URL=http://your-node-server:3000
```

Use the `useApi` hook for making API requests:

```typescript
import { useApi } from './hooks/useApi'

const { request, loading, error } = useApi()
const data = await request('GET', '/api/songs')
```

## Development Server Configuration

The dev server runs on port `3001` by default. To change this, modify `vite.config.ts` or set the port when running:

```bash
yarn dev -- --port 3002
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run linting: `yarn lint`
4. Commit your changes
5. Push and create a pull request

## License

Private project - Singalong

## Support

For issues or questions about the Singalong Admin service, refer to the main Singalong project documentation.
