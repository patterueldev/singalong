/** Data Models for Admin UI */

export interface User {
  id: string
  username: string
  role: 'admin' | 'controller' | 'player'
}

export interface Session {
  code: string // 4-digit session code
  title: string
  vibes: string
  max_users: number
  status: 'active' | 'paused' | 'ended'
  created_at: string
  created_by: string
  user_count: number
}

export interface Playback {
  song_id: string | null
  title: string
  artist: string
  duration: number // seconds
  elapsed: number // seconds
  is_playing: boolean
  player_id: string | null
  player_name?: string
}

export interface Player {
  id: string
  name: string
  hostname?: string
  status: 'idle' | 'playing' | 'offline' | 'online'
}

export interface AuthResponse {
  access_token: string
  token_type: string
}

export interface SessionsListResponse {
  sessions: Session[]
  total: number
  offset: number
  limit: number
}

export interface ErrorResponse {
  status: string
  code: string
  message: string
  details?: Record<string, unknown>
}
