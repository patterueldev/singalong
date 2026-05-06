import axios, { AxiosError } from 'axios'
import type { AuthResponse } from '../types/models'
import type { InternalAxiosRequestConfig } from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
const ACCESS_TOKEN_KEY = 'admin_access_token'
const REFRESH_TOKEN_KEY = 'admin_refresh_token'
const TOKEN_EXPIRY_KEY = 'admin_token_expiry'

let refreshTokenPromise: Promise<boolean> | null = null

interface CustomAxiosRequestConfig extends InternalAxiosRequestConfig {
  _retry?: boolean
}

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

console.log('[authService] Created axios instance with baseURL:', API_BASE_URL)

// Auto-add token to requests
api.interceptors.request.use((config) => {
  const token = getToken()
  console.log('[authService] REQUEST INTERCEPTOR:', {
    url: config.url,
    method: config.method,
    hasToken: !!token,
    tokenLength: token?.length || 0,
  })
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

console.log('[authService] Registered request interceptor')

// Handle 401 errors with automatic token refresh
api.interceptors.response.use(
  (response) => {
    console.log('[authService] RESPONSE SUCCESS:', {
      url: response.config.url,
      status: response.status,
    })
    return response
  },
  async (error: AxiosError) => {
    const originalRequest = error.config as CustomAxiosRequestConfig
    
    console.log('[authService] RESPONSE ERROR:', {
      url: originalRequest?.url,
      status: error.response?.status,
      message: error.message,
    })

    // Only handle 401 errors
    if (error.response?.status !== 401) {
      console.log('[authService] Not a 401, passing through')
      return Promise.reject(error)
    }

    console.log('[authService] 401 DETECTED - Starting refresh flow')

    // Prevent infinite loop: don't retry the refresh endpoint itself
    if (originalRequest?.url?.includes('/auth/refresh')) {
      console.log('[authService] 401 on refresh endpoint, clearing tokens and redirecting')
      // Refresh token is invalid, clear everything and redirect to login
      clearTokens()
      window.location.href = '/login'
      return Promise.reject(error)
    }

    // Prevent multiple retries of the same request
    if (originalRequest._retry) {
      console.log('[authService] Already retried once, giving up and redirecting')
      // Already tried to refresh and retry, give up
      clearTokens()
      window.location.href = '/login'
      return Promise.reject(error)
    }

    originalRequest._retry = true

    try {
      // Attempt to refresh the token
      const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
      
      console.log('[authService] Attempting refresh with token:', {
        hasRefreshToken: !!refreshToken,
        refreshTokenLength: refreshToken?.length || 0,
      })
      
      if (!refreshToken) {
        console.log('[authService] No refresh token available, redirecting')
        // No refresh token available
        window.location.href = '/login'
        return Promise.reject(error)
      }

      console.log('[authService] Calling POST /auth/refresh')
      const response = await api.post('/auth/refresh', {
        refresh_token: refreshToken,
      })

      const { access_token, refresh_token, expires_in } = response.data

      console.log('[authService] Refresh successful, updating tokens:', {
        newTokenLength: access_token?.length || 0,
        expiresIn: expires_in,
      })

      // Update tokens in localStorage
      localStorage.setItem(ACCESS_TOKEN_KEY, access_token)
      localStorage.setItem(REFRESH_TOKEN_KEY, refresh_token)
      const expiryTime = Date.now() + expires_in * 1000
      localStorage.setItem(TOKEN_EXPIRY_KEY, expiryTime.toString())

      // Retry the original request with new token
      console.log('[authService] Retrying original request:', originalRequest.url)
      originalRequest.headers.Authorization = `Bearer ${access_token}`
      return api(originalRequest)
    } catch (err) {
      console.error('[authService] Refresh failed:', {
        error: err instanceof Error ? err.message : String(err),
      })
      // Refresh failed, redirect to login
      clearTokens()
      window.location.href = '/login'
      return Promise.reject(error)
    }
  }
)

console.log('[authService] Registered response interceptor')

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
