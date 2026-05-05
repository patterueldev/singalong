import { useState, useCallback } from 'react'
import { authService, getToken } from '../services/authService'

export interface AuthState {
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    isAuthenticated: !!getToken(),
    isLoading: false,
    error: null,
  })

  const login = useCallback(async (username: string, password: string) => {
    setState({ isAuthenticated: false, isLoading: true, error: null })
    try {
      await authService.login(username, password)
      setState({ isAuthenticated: true, isLoading: false, error: null })
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed'
      setState({ isAuthenticated: false, isLoading: false, error: message })
      throw err
    }
  }, [])

  const logout = useCallback(() => {
    authService.logout()
    setState({ isAuthenticated: false, isLoading: false, error: null })
  }, [])

  return {
    ...state,
    login,
    logout,
  }
}
