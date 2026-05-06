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

  // ALWAYS fetch assigned player on mount and when session changes
  // This is separate from the polling of available players
  useEffect(() => {
    if (!currentSession?.code) {
      console.log('[usePlayback] No currentSession, clearing assigned player')
      setState((prev) => ({ ...prev, assignedPlayer: null }))
      return
    }

    const fetchAssignedPlayer = async () => {
      try {
        const sessionResponse = await api.get(
          `/sessions/${currentSession.code}`
        )
        const sessionData = sessionResponse.data
        console.log('[usePlayback] Fetched assigned player:', {
          player_id: sessionData?.player_id,
          player_name: sessionData?.player_name,
          player_platform: sessionData?.player_platform,
        })

        let assignedPlayer: Player | null = null
        if (sessionData?.player_id && sessionData?.player_name) {
          assignedPlayer = {
            id: sessionData.player_id,
            name: sessionData.player_name,
            platform: sessionData.player_platform || 'unknown',
            status: 'connected' as any,
          }
          console.log('[usePlayback] ✓ Assigned player:', assignedPlayer.name, `(${assignedPlayer.platform})`)
        } else {
          console.log('[usePlayback] No assigned player')
        }

        setState((prev) => ({
          ...prev,
          assignedPlayer: assignedPlayer,
        }))
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Failed to fetch session'
        console.error('[usePlayback] Error fetching assigned player:', errorMsg)
      }
    }

    fetchAssignedPlayer()
  }, [currentSession?.code])

  // Poll available players ONLY when modal is open
  useEffect(() => {
    if (!currentSession?.code) {
      console.log('[usePlayback] No currentSession, skipping poll')
      return
    }

    if (!isPlayerModalOpen) {
      console.log('[usePlayback] SelectPlayerModal is closed, skipping poll')
      return
    }

    console.log('[usePlayback] Starting poll for available players')

    const fetchAvailablePlayers = async () => {
      console.log('[usePlayback] Polling available players')
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        // Fetch available players
        const playersResponse = await api.get(
          `/players/available`
        )
        // Handle both direct array, {players: [...]}, and {available_players: [...]} response
        const players = Array.isArray(playersResponse.data) 
          ? playersResponse.data 
          : (playersResponse.data?.players || playersResponse.data?.available_players || [])
        console.log('[usePlayback] Fetched', players.length, 'available players')
        
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
        const errorMsg = err instanceof Error ? err.message : 'Failed to fetch available players'
        console.error('[usePlayback] Fetch error:', errorMsg)
        setState((prev) => ({
          ...prev,
          error: errorMsg,
          isLoading: false,
        }))
      }
    }

    // Fetch immediately on modal open
    fetchAvailablePlayers()

    // Set up polling every 5 seconds
    console.log('[usePlayback] Setting up 5-second poll interval')
    const pollInterval = setInterval(fetchAvailablePlayers, 5000)

    return () => {
      console.log('[usePlayback] Cleaning up poll interval')
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
    
    setState((prev) => ({ ...prev, isLoading: true, error: null }))
    try {
      // Fetch available players
      const playersResponse = await api.get('/players/available')
      const players = Array.isArray(playersResponse.data) 
        ? playersResponse.data 
        : (playersResponse.data?.players || playersResponse.data?.available_players || [])
      console.log('[usePlayback.refreshPlayback] Fetched', players.length, 'available players')
      
      const mappedPlayers: Player[] = players.map(
        (p: { id: string; name: string; platform: string; status: string }) => ({
          id: p.id,
          name: p.name,
          platform: p.platform,
          status: p.status as any,
        })
      )

      // Fetch session details to get current assigned player
      const sessionResponse = await api.get(`/sessions/${currentSession.code}`)
      const sessionData = sessionResponse.data
      console.log('[usePlayback.refreshPlayback] Fetched assigned player:', {
        player_id: sessionData?.player_id,
        player_name: sessionData?.player_name,
        player_platform: sessionData?.player_platform,
      })

      let assignedPlayer: Player | null = null
      if (sessionData?.player_id && sessionData?.player_name) {
        assignedPlayer = {
          id: sessionData.player_id,
          name: sessionData.player_name,
          platform: sessionData.player_platform || 'unknown',
          status: 'connected' as any,
        }
        console.log('[usePlayback.refreshPlayback] ✓ Assigned player:', assignedPlayer.name, `(${assignedPlayer.platform})`)
      } else {
        console.log('[usePlayback.refreshPlayback] No assigned player')
      }

      setState((prev) => ({
        ...prev,
        availablePlayers: mappedPlayers,
        assignedPlayer: assignedPlayer,
        isLoading: false,
      }))
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to refresh playback'
      console.error('[usePlayback.refreshPlayback] Error:', errorMsg)
      setState((prev) => ({
        ...prev,
        error: errorMsg,
        isLoading: false,
      }))
    }
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
