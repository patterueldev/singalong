import axios from 'axios'
import type { AuthResponse } from '../types/models'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
const TOKEN_KEY = 'admin_access_token'

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
    const response = await api.post<AuthResponse>('/api/auth/admin', {
      username,
      password,
    })
    const token = response.data.access_token
    setToken(token)
    return token
  },

  logout(): void {
    clearToken()
  },

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY)
  },

  setToken(token: string): void {
    localStorage.setItem(TOKEN_KEY, token)
  },

  clearToken(): void {
    localStorage.removeItem(TOKEN_KEY)
  },

  isTokenValid(): boolean {
    return !!this.getToken()
  },
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token)
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY)
}

export default api
