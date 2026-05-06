import { useState, useCallback, useEffect } from 'react'
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

  // Auto-refresh token before expiry
  useEffect(() => {
    const refreshInterval = setInterval(async () => {
      if (authService.shouldRefreshToken()) {
        try {
          const success = await authService.refreshToken()
          if (!success) {
            // Refresh failed, logout the user
            setState({ isAuthenticated: false, isLoading: false, error: null })
          }
        } catch (err) {
          // Silent failure - next API call will handle 401
          console.debug('Token refresh failed:', err)
        }
      }
    }, 60000) // Check every minute

    return () => clearInterval(refreshInterval)
  }, [])

  return {
    ...state,
    login,
    logout,
  }
}

