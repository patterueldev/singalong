import api from './authService'
import { getToken } from './authService'
import type { Session } from '../types/models'

interface SessionsListResponse {
  sessions: Session[]
  total: number
  offset: number
  limit: number
}

export const sessionService = {
  async getSessions(): Promise<Session[]> {
    const token = getToken()
    console.log('[sessionService] Calling getSessions', {
      hasToken: !!token,
      tokenLength: token?.length || 0,
    })
    const response = await api.get<SessionsListResponse>('/sessions')
    console.log('[sessionService] getSessions response:', response.status)
    return response.data.sessions
  },

  async createSession(title: string, vibes?: string): Promise<Session> {
    const response = await api.post<Session>('/sessions', {
      title,
      vibes: vibes || '',
      max_users: 0,
    })
    return response.data
  },

  async getSession(code: string): Promise<Session> {
    const response = await api.get<Session>(`/sessions/${code}`)
    return response.data
  },

  async endSession(code: string): Promise<void> {
    await api.put(`/sessions/${code}`, {
      status: 'ended',
    })
  },

  async updateSession(code: string, title: string, vibes?: string): Promise<Session> {
    const response = await api.put<Session>(`/sessions/${code}`, {
      title,
      vibes,
    })
    return response.data
  },
}
