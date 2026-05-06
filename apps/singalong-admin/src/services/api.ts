import axios, { AxiosError } from 'axios'
import type { InternalAxiosRequestConfig } from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

interface CustomAxiosRequestConfig extends InternalAxiosRequestConfig {
  _retry?: boolean
}

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Auto-add token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 errors with automatic token refresh
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as CustomAxiosRequestConfig

    // Only handle 401 errors
    if (error.response?.status !== 401) {
      return Promise.reject(error)
    }

    // Prevent infinite loop: don't retry the refresh endpoint itself
    if (originalRequest?.url?.includes('/auth/refresh')) {
      // Refresh token is invalid, clear everything and redirect to login
      localStorage.removeItem('admin_access_token')
      localStorage.removeItem('admin_refresh_token')
      localStorage.removeItem('admin_token_expiry')
      window.location.href = '/login'
      return Promise.reject(error)
    }

    // Prevent multiple retries of the same request
    if (originalRequest._retry) {
      // Already tried to refresh and retry, give up
      localStorage.removeItem('admin_access_token')
      localStorage.removeItem('admin_refresh_token')
      localStorage.removeItem('admin_token_expiry')
      window.location.href = '/login'
      return Promise.reject(error)
    }

    originalRequest._retry = true

    try {
      // Attempt to refresh the token
      const refreshToken = localStorage.getItem('admin_refresh_token')
      
      if (!refreshToken) {
        // No refresh token available
        window.location.href = '/login'
        return Promise.reject(error)
      }

      const response = await api.post('/auth/refresh', {
        refresh_token: refreshToken,
      })

      const { access_token, refresh_token, expires_in } = response.data

      // Update tokens in localStorage
      localStorage.setItem('admin_access_token', access_token)
      localStorage.setItem('admin_refresh_token', refresh_token)
      const expiryTime = Date.now() + expires_in * 1000
      localStorage.setItem('admin_token_expiry', expiryTime.toString())

      // Retry the original request with new token
      originalRequest.headers.Authorization = `Bearer ${access_token}`
      return api(originalRequest)
    } catch (refreshError) {
      // Refresh failed, redirect to login
      localStorage.removeItem('admin_access_token')
      localStorage.removeItem('admin_refresh_token')
      localStorage.removeItem('admin_token_expiry')
      window.location.href = '/login'
      return Promise.reject(refreshError)
    }
  }
)

export default api

