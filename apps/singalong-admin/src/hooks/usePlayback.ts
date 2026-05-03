import { useState, useCallback, useEffect } from 'react'
import { useSessions } from './useSessions'
import type { Playback, Player } from '../types/models'
import api from '../services/api'

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

export interface PlaybackState {
  nowPlaying: Playback
  assignedPlayer: Player | null
  availablePlayers: Player[]
  isLoading: boolean
  error: string | null
}

export function usePlayback() {
  const { currentSession } = useSessions()
  const [state, setState] = useState<PlaybackState>({
    nowPlaying: MOCK_PLAYBACK,
    assignedPlayer: null,
    availablePlayers: [],
    isLoading: false,
    error: null,
  })

  // Poll available players every 5 seconds when session is selected
  useEffect(() => {
    if (!currentSession?.code) return

    const fetchAvailablePlayers = async () => {
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        const response = await api.get(
          `/api/sessions/${currentSession.code}/available-players`
        )
        const players = response.data || []
        
        // Convert Node response format to Player model
        const mappedPlayers: Player[] = players.map(
          (p: { id: string; name: string; platform: string; status: string }) => ({
            id: p.id,
            name: p.name,
            platform: p.platform,
            status: p.status as any,
          })
        )

        setState((prev) => ({
          ...prev,
          availablePlayers: mappedPlayers,
          isLoading: false,
        }))
      } catch (err) {
        setState((prev) => ({
          ...prev,
          error: err instanceof Error ? err.message : 'Failed to fetch available players',
          isLoading: false,
        }))
      }
    }

    // Fetch immediately on mount
    fetchAvailablePlayers()

    // Set up polling every 5 seconds
    const pollInterval = setInterval(fetchAvailablePlayers, 5000)

    return () => clearInterval(pollInterval)
  }, [currentSession?.code])

  const selectPlayer = useCallback(
    async (playerId: string) => {
      if (!currentSession?.code) {
        setState((prev) => ({
          ...prev,
          error: 'No session selected',
        }))
        return
      }

      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        // Call Node API to select player
        await api.post(`/api/sessions/${currentSession.code}/select-player`, {
          player_id: playerId,
        })

        // Update local state with selected player
        const selectedPlayer = state.availablePlayers.find((p) => p.id === playerId)
        setState((prev) => ({
          ...prev,
          assignedPlayer: selectedPlayer || null,
          isLoading: false,
        }))
      } catch (err) {
        setState((prev) => ({
          ...prev,
          error: err instanceof Error ? err.message : 'Failed to select player',
          isLoading: false,
        }))
      }
    },
    [currentSession?.code, state.availablePlayers]
  )

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
