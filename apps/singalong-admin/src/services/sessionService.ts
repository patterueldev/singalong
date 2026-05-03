import api from './authService'
import type { Session, SessionsResponse } from '../types/models'

export const sessionService = {
  async getSessions(): Promise<Session[]> {
    const response = await api.get<SessionsResponse>('/api/admin/sessions')
    return response.data.sessions
  },

  async createSession(name: string, vibes?: string): Promise<Session> {
    const response = await api.post<Session>('/api/admin/sessions', {
      name,
      vibes,
    })
    return response.data
  },

  async getSession(id: string): Promise<Session> {
    const response = await api.get<Session>(`/api/admin/sessions/${id}`)
    return response.data
  },

  async endSession(id: string): Promise<void> {
    await api.post(`/api/admin/sessions/${id}/end`)
  },

  async updateSession(id: string, name: string, vibes?: string): Promise<Session> {
    const response = await api.put<Session>(`/api/admin/sessions/${id}`, {
      name,
      vibes,
    })
    return response.data
  },
}
