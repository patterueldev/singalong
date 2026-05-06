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
 * - Only fetches when isOpen is true
 * - Auto-refreshes every 2 seconds while open
 * - Stops polling when closed to save bandwidth
 */
export function useAvailablePlayers(isOpen: boolean = true): UseAvailablePlayersReturn {
  const [players, setPlayers] = useState<AvailablePlayer[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectingPlayerId, setSelectingPlayerId] = useState<string | null>(null)
  const refreshIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  console.log('[useAvailablePlayers] Hook instantiated with isOpen:', isOpen)

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

  // Initial fetch and set up auto-refresh (only when modal is open)
  useEffect(() => {
    console.log('[useAvailablePlayers.useEffect] isOpen changed to:', isOpen)
    if (!isOpen) {
      console.log('[useAvailablePlayers.useEffect] Modal is closed, stopping polling')
      // Stop polling when modal is closed
      if (refreshIntervalRef.current) {
        console.log('[useAvailablePlayers.useEffect] Clearing interval')
        clearInterval(refreshIntervalRef.current)
        refreshIntervalRef.current = null
      }
      return
    }

    console.log('[useAvailablePlayers.useEffect] Modal is open, starting polling')
    refreshPlayers()

    // Auto-refresh every 2 seconds while open
    refreshIntervalRef.current = setInterval(() => {
      console.log('[useAvailablePlayers.useEffect] Polling interval triggered')
      refreshPlayers()
    }, 2000)

    return () => {
      console.log('[useAvailablePlayers.useEffect] Cleanup: clearing interval')
      if (refreshIntervalRef.current) {
        clearInterval(refreshIntervalRef.current)
      }
    }
  }, [refreshPlayers, isOpen])

  return {
    players,
    loading,
    error,
    refreshPlayers,
    selectPlayer,
    selectingPlayerId,
  }
}
