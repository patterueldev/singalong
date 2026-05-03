import api from './authService'
import type { Session } from '../types/models'

interface SessionsListResponse {
  sessions: Session[]
  total: number
  offset: number
  limit: number
}

export const sessionService = {
  async getSessions(): Promise<Session[]> {
    const response = await api.get<SessionsListResponse>('/api/sessions')
    return response.data.sessions
  },

  async createSession(title: string, vibes?: string): Promise<Session> {
    const response = await api.post<Session>('/api/sessions', {
      title,
      vibes: vibes || '',
      max_users: 0,
    })
    return response.data
  },

  async getSession(code: string): Promise<Session> {
    const response = await api.get<Session>(`/api/sessions/${code}`)
    return response.data
  },

  async endSession(code: string): Promise<void> {
    await api.put(`/api/sessions/${code}`, {
      status: 'ended',
    })
  },

  async updateSession(code: string, title: string, vibes?: string): Promise<Session> {
    const response = await api.put<Session>(`/api/sessions/${code}`, {
      title,
      vibes,
    })
    return response.data
  },
}
