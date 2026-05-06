import { useState, useCallback, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { sessionService } from '../services/sessionService'
import type { Session } from '../types/models'

export interface SessionsState {
  sessions: Session[]
  currentSession: Session | null
  isLoading: boolean
  error: string | null
}

export function useSessions() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [state, setState] = useState<SessionsState>({
    sessions: [],
    currentSession: null,
    isLoading: false,
    error: null,
  })

  const refreshSessions = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }))
    try {
      const sessions = await sessionService.getSessions()
      setState((prev) => ({ ...prev, sessions, isLoading: false }))
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load sessions'
      setState((prev) => ({ ...prev, isLoading: false, error: message }))
    }
  }, [])

  useEffect(() => {
    refreshSessions()
  }, [refreshSessions])

  const selectSession = useCallback(
    async (code: string) => {
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        const session = await sessionService.getSession(code)
        setState((prev) => ({ ...prev, currentSession: session, isLoading: false }))
        // Update URL to include session code
        setSearchParams({ sessionCode: code })
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to load session'
        setState((prev) => ({ ...prev, isLoading: false, error: message }))
      }
    },
    [setSearchParams]
  )

  // Restore session from URL on mount or when URL changes
  useEffect(() => {
    const sessionCode = searchParams.get('sessionCode')
    if (sessionCode && state.currentSession?.code !== sessionCode) {
      selectSession(sessionCode)
    }
  }, [searchParams, state.currentSession?.code, selectSession])

  const createSession = useCallback(
    async (title: string, vibes?: string) => {
      setState((prev) => ({ ...prev, isLoading: true, error: null }))
      try {
        const newSession = await sessionService.createSession(title, vibes)
        setState((prev) => ({
          ...prev,
          sessions: [...prev.sessions, newSession],
          isLoading: false,
        }))
        // Refresh to sync with server state
        await refreshSessions()
        return newSession
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to create session'
        setState((prev) => ({ ...prev, isLoading: false, error: message }))
        throw err
      }
    },
    [refreshSessions]
  )

  const endSession = useCallback(async (code: string) => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }))
    try {
      await sessionService.endSession(code)
      setState((prev) => ({
        ...prev,
        sessions: prev.sessions.map((s) => (s.code === code ? { ...s, status: 'ended' } : s)),
        currentSession:
          prev.currentSession?.code === code
            ? { ...prev.currentSession, status: 'ended' }
            : prev.currentSession,
        isLoading: false,
      }))
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to end session'
      setState((prev) => ({ ...prev, isLoading: false, error: message }))
    }
  }, [])

  return {
    ...state,
    createSession,
    selectSession,
    endSession,
    refreshSessions,
  }
}
