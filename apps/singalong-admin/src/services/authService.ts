import axios from 'axios'
import type { AuthResponse } from '../types/models'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
const ACCESS_TOKEN_KEY = 'admin_access_token'
const REFRESH_TOKEN_KEY = 'admin_refresh_token'
const TOKEN_EXPIRY_KEY = 'admin_token_expiry'

let refreshTokenPromise: Promise<boolean> | null = null

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Auto-add token to requests
api.interceptors.request.use((config) => {
  const token = getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export const authService = {
  async login(username: string, password: string): Promise<string> {
    const response = await api.post<AuthResponse>('/auth/admin', {
      username,
      password,
    })
    
    const {
      access_token,
      refresh_token,
      expires_in,
    } = response.data
    
    setTokens(access_token, refresh_token, expires_in)
    return access_token
  },

  async refreshToken(): Promise<boolean> {
    // Prevent multiple simultaneous refresh requests
    if (refreshTokenPromise) {
      return refreshTokenPromise
    }

    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
    
    if (!refreshToken) {
      clearTokens()
      return false
    }

    refreshTokenPromise = (async () => {
      try {
        const response = await api.post<AuthResponse>('/auth/refresh', {
          refresh_token: refreshToken,
        })
        
        const {
          access_token,
          refresh_token: newRefreshToken,
          expires_in,
        } = response.data
        
        setTokens(access_token, newRefreshToken, expires_in)
        return true
      } catch {
        // Refresh failed - tokens are invalid
        clearTokens()
        return false
      } finally {
        refreshTokenPromise = null
      }
    })()

    return refreshTokenPromise
  },

  logout(): void {
    clearTokens()
  },

  getToken(): string | null {
    return localStorage.getItem(ACCESS_TOKEN_KEY)
  },

  getRefreshToken(): string | null {
    return localStorage.getItem(REFRESH_TOKEN_KEY)
  },

  getTokenExpiry(): number | null {
    const expiry = localStorage.getItem(TOKEN_EXPIRY_KEY)
    return expiry ? parseInt(expiry, 10) : null
  },

  isTokenExpired(): boolean {
    const expiry = this.getTokenExpiry()
    if (!expiry) return true
    return Date.now() >= expiry
  },

  shouldRefreshToken(): boolean {
    const expiry = this.getTokenExpiry()
    if (!expiry) return false
    // Refresh if expires in less than 5 minutes
    const fiveMinutesMs = 5 * 60 * 1000
    return Date.now() >= expiry - fiveMinutesMs
  },

  isTokenValid(): boolean {
    return !!this.getToken() && !this.isTokenExpired()
  },
}

function setTokens(
  accessToken: string,
  refreshToken: string,
  expiresInSeconds: number
): void {
  localStorage.setItem(ACCESS_TOKEN_KEY, accessToken)
  localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
  const expiryTime = Date.now() + expiresInSeconds * 1000
  localStorage.setItem(TOKEN_EXPIRY_KEY, expiryTime.toString())
}

function clearTokens(): void {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
  localStorage.removeItem(TOKEN_EXPIRY_KEY)
}

export function setToken(token: string): void {
  localStorage.setItem(ACCESS_TOKEN_KEY, token)
}

export function getToken(): string | null {
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

export function clearToken(): void {
  clearTokens()
}

export default api
