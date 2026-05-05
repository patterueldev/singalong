import api from './authService'

export interface AvailablePlayer {
  id: string
  name: string
  platform: string
  status: string
  connected_at: string
}

interface GetAvailablePlayersResponse {
  available_players: AvailablePlayer[]
  count: number
}

interface SelectPlayerResponse {
  success: boolean
  player_id: string
  player_name: string
  session_code: string
  message: string
}

export const playerService = {
  /**
   * Get list of available players (discovering/waiting for session)
   */
  async getAvailablePlayers(): Promise<AvailablePlayer[]> {
    const response = await api.get<GetAvailablePlayersResponse>('/players/available')
    return response.data.available_players || []
  },

  /**
   * Lock a player to a specific session
   * @param playerId - UUID of the player to lock
   * @param sessionCode - 4-digit session code (e.g., "0001")
   */
  async selectPlayer(playerId: string, sessionCode: string): Promise<SelectPlayerResponse> {
    const response = await api.post<SelectPlayerResponse>('/players/select', null, {
      params: {
        player_id: playerId,
        session_code: sessionCode,
      },
    })
    return response.data
  },
}
