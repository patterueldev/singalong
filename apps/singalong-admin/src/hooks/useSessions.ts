import { useState, useCallback, useEffect } from 'react'
import { sessionService } from '../services/sessionService'
import type { Session } from '../types/models'

export interface SessionsState {
  sessions: Session[]
  currentSession: Session | null
  isLoading: boolean
  error: string | null
}

export function useSessions() {
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
        return newSession
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to create session'
        setState((prev) => ({ ...prev, isLoading: false, error: message }))
        throw err
      }
    },
    []
  )

  const selectSession = useCallback(async (code: string) => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }))
    try {
      const session = await sessionService.getSession(code)
      setState((prev) => ({ ...prev, currentSession: session, isLoading: false }))
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load session'
      setState((prev) => ({ ...prev, isLoading: false, error: message }))
    }
  }, [])

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
