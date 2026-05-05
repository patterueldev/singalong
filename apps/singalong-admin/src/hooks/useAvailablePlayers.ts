import { useState, useEffect, useCallback, useRef } from 'react'
import { playerService, type AvailablePlayer } from '../services/playerService'

export interface UseAvailablePlayersReturn {
  players: AvailablePlayer[]
  loading: boolean
  error: string | null
  refreshPlayers: () => Promise<void>
  selectPlayer: (playerId: string, sessionCode: string) => Promise<void>
  selectingPlayerId: string | null
}

/**
 * Hook to manage available players with auto-refresh
 * - Fetches available players on mount and every 2 seconds
 * - Handles loading/error states
 * - Provides methods to refresh and select players
 */
export function useAvailablePlayers(): UseAvailablePlayersReturn {
  const [players, setPlayers] = useState<AvailablePlayer[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectingPlayerId, setSelectingPlayerId] = useState<string | null>(null)
  const refreshIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // Fetch available players
  const refreshPlayers = useCallback(async () => {
    try {
      setError(null)
      const fetchedPlayers = await playerService.getAvailablePlayers()
      console.log('[useAvailablePlayers] Fetched:', fetchedPlayers.length, 'players')
      setPlayers(fetchedPlayers)
      setLoading(false)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch players'
      console.error('[useAvailablePlayers] Error:', message)
      setError(message)
      setLoading(false)
    }
  }, [])

  // Select a player for the session
  const selectPlayer = useCallback(
    async (playerId: string, sessionCode: string) => {
      try {
        setSelectingPlayerId(playerId)
        setError(null)
        await playerService.selectPlayer(playerId, sessionCode)
        // Refresh the list after successful selection
        await refreshPlayers()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to select player'
        setError(message)
      } finally {
        setSelectingPlayerId(null)
      }
    },
    [refreshPlayers]
  )

  // Initial fetch and set up auto-refresh
  useEffect(() => {
    refreshPlayers()

    // Auto-refresh every 2 seconds
    refreshIntervalRef.current = setInterval(() => {
      refreshPlayers()
    }, 2000)

    return () => {
      if (refreshIntervalRef.current) {
        clearInterval(refreshIntervalRef.current)
      }
    }
  }, [refreshPlayers])

  return {
    players,
    loading,
    error,
    refreshPlayers,
    selectPlayer,
    selectingPlayerId,
  }
}
