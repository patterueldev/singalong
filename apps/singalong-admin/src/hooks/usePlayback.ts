import { useState, useCallback } from 'react'
import type { Playback, Player } from '../types/models'

// Mock data for MVP
const MOCK_PLAYBACK: Playback = {
  song_id: null,
  title: 'No song playing',
  artist: 'Unknown',
  duration: 0,
  elapsed: 0,
  is_playing: false,
  player_id: null,
  player_name: undefined,
}

const MOCK_PLAYERS: Player[] = [
  { id: 'player-1', name: 'Living Room', status: 'idle' },
  { id: 'player-2', name: 'Bedroom', status: 'offline' },
]

export interface PlaybackState {
  nowPlaying: Playback
  assignedPlayer: Player | null
  availablePlayers: Player[]
  isLoading: boolean
  error: string | null
}

export function usePlayback() {
  const [state, setState] = useState<PlaybackState>({
    nowPlaying: MOCK_PLAYBACK,
    assignedPlayer: null,
    availablePlayers: MOCK_PLAYERS,
    isLoading: false,
    error: null,
  })

  const selectPlayer = useCallback((playerId: string) => {
    setState((prev) => {
      const player = prev.availablePlayers.find((p) => p.id === playerId)
      return {
        ...prev,
        assignedPlayer: player || null,
      }
    })
  }, [])

  const play = useCallback(() => {
    setState((prev) => ({
      ...prev,
      nowPlaying: { ...prev.nowPlaying, is_playing: true },
    }))
  }, [])

  const pause = useCallback(() => {
    setState((prev) => ({
      ...prev,
      nowPlaying: { ...prev.nowPlaying, is_playing: false },
    }))
  }, [])

  const seek = useCallback((seconds: number) => {
    setState((prev) => ({
      ...prev,
      nowPlaying: { ...prev.nowPlaying, elapsed: seconds },
    }))
  }, [])

  return {
    ...state,
    selectPlayer,
    play,
    pause,
    seek,
  }
}
