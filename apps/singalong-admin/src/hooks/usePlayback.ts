import { useState, useCallback, useEffect } from 'react'
import { useSessions } from './useSessions'
import type { Playback, Player } from '../types/models'
import api from '../services/authService'

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

export function usePlayback(isPlayerModalOpen: boolean = false) {
  const { currentSession } = useSessions()
  const [state, setState] = useState<PlaybackState>({
    nowPlaying: MOCK_PLAYBACK,
    assignedPlayer: null,
    availablePlayers: [],
    isLoading: false,
    error: null,
  })

  // Poll available players and session details every 5 seconds - ONLY when modal is open
  useEffect(() => {
    if (!currentSession?.code) {
      console.log('[usePlayback] No currentSession, skipping poll')
      return
    }

    if (!isPlayerModalOpen) {
      console.log('[usePlayback] SelectPlayerModal is closed, skipping poll')
      return
    }

    console.log('[usePlayback] Starting poll for session:', currentSession.code)

    const fetchData = async () => {
      console.log('[usePlayback.fetchData] Polling available players')
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        // Fetch available players
        const playersResponse = await api.get(
          `/players/available`
        )
        const players = playersResponse.data || []
        console.log('[usePlayback.fetchData] Fetched', players.length, 'available players')
        
        // Convert Node response format to Player model
        const mappedPlayers: Player[] = players.map(
          (p: { id: string; name: string; platform: string; status: string }) => ({
            id: p.id,
            name: p.name,
            platform: p.platform,
            status: p.status as any,
          })
        )

        // Fetch session details to get current assigned player
        const sessionResponse = await api.get(
          `/sessions/${currentSession.code}`
        )
        const sessionData = sessionResponse.data
        console.log('[usePlayback] Session details response:', { player_id: sessionData?.player_id, player_name: sessionData?.player_name })

        // If player is assigned in session, use that; otherwise None Selected
        let assignedPlayer: Player | null = null
        if (sessionData?.player_id && sessionData?.player_name) {
          assignedPlayer = {
            id: sessionData.player_id,
            name: sessionData.player_name,
            platform: 'unknown',
            status: 'connected' as any,
          }
          console.log('[usePlayback] ✓ Assigned player found:', assignedPlayer.name)
        } else {
          console.log('[usePlayback] No assigned player yet')
        }

        setState((prev) => ({
          ...prev,
          availablePlayers: mappedPlayers,
          assignedPlayer: assignedPlayer,
          isLoading: false,
        }))
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Failed to fetch data'
        console.error('[usePlayback] Fetch error:', errorMsg)
        setState((prev) => ({
          ...prev,
          error: errorMsg,
          isLoading: false,
        }))
      }
    }

    // Fetch immediately on mount
    fetchData()

    // Set up polling every 5 seconds
    console.log('[usePlayback] Setting up 5-second poll interval')
    const pollInterval = setInterval(fetchData, 5000)

    return () => {
      console.log('[usePlayback] Cleaning up poll interval for session:', currentSession.code)
      clearInterval(pollInterval)
    }
  }, [currentSession?.code, isPlayerModalOpen])

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

  const refreshPlayback = useCallback(async () => {
    if (!currentSession?.code) return
    
    const fetchData = async () => {
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        // Fetch available players
        const playersResponse = await api.get(
          `/players/available`
        )
        const players = playersResponse.data || []
        console.log('[usePlayback.fetchData] Fetched', players.length, 'available players')
        
        // Convert Node response format to Player model
        const mappedPlayers: Player[] = players.map(
          (p: { id: string; name: string; platform: string; status: string }) => ({
            id: p.id,
            name: p.name,
            platform: p.platform,
            status: p.status as any,
          })
        )

        // Fetch session details to get current assigned player
        const sessionResponse = await api.get(
          `/sessions/${currentSession.code}`
        )
        const sessionData = sessionResponse.data
        console.log('[usePlayback] Refreshed playback data:', { player_id: sessionData?.player_id, player_name: sessionData?.player_name })

        // If player is assigned in session, use that; otherwise None Selected
        let assignedPlayer: Player | null = null
        if (sessionData?.player_id && sessionData?.player_name) {
          assignedPlayer = {
            id: sessionData.player_id,
            name: sessionData.player_name,
            platform: 'unknown',
            status: 'connected' as any,
          }
          console.log('[usePlayback] ✓ Assigned player found after refresh:', assignedPlayer.name)
        } else {
          console.log('[usePlayback] No assigned player after refresh')
        }

        setState((prev) => ({
          ...prev,
          availablePlayers: mappedPlayers,
          assignedPlayer: assignedPlayer,
          isLoading: false,
        }))
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Failed to refresh playback data'
        console.error('[usePlayback] Refresh error:', errorMsg)
        setState((prev) => ({
          ...prev,
          error: errorMsg,
          isLoading: false,
        }))
      }
    }

    await fetchData()
  }, [currentSession?.code])

  return {
    ...state,
    selectPlayer,
    refreshPlayback,
    play,
    pause,
    seek,
  }
}
