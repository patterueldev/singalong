/** Data Models for Admin UI */

export interface User {
  id: string
  username: string
  role: 'admin' | 'controller' | 'player'
}

export interface Session {
  id: string
  name: string
  code: string
  status: 'active' | 'ended'
  vibes?: string
  player_count: number
  attendee_count: number
  created_at: string
  created_by?: string
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
  status: 'idle' | 'playing' | 'offline'
}

export interface AuthResponse {
  access_token: string
  token_type: string
}

export interface SessionsResponse {
  sessions: Session[]
  total: number
}

export interface ErrorResponse {
  status: string
  code: string
  message: string
  details?: Record<string, unknown>
}
