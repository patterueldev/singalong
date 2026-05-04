import { useState } from 'react'
import type { AvailablePlayer } from '../services/playerService'
import '../styles/WaitingPlayersList.css'

interface WaitingPlayersListProps {
  players: AvailablePlayer[]
  loading: boolean
  error: string | null
  onSelectPlayer: (playerId: string) => Promise<void>
  selectingPlayerId: string | null
  sessionCode: string
}

export function WaitingPlayersList({
  players,
  loading,
  error,
  onSelectPlayer,
  selectingPlayerId,
  sessionCode,
}: WaitingPlayersListProps) {
  const [selectedPlayerId, setSelectedPlayerId] = useState<string | null>(null)

  const handleSelectClick = async () => {
    if (!selectedPlayerId) return
    try {
      await onSelectPlayer(selectedPlayerId)
      setSelectedPlayerId(null)
    } catch (err) {
      console.error('Failed to select player:', err)
    }
  }

  const getPlatformIcon = (platform: string): string => {
    switch (platform) {
      case 'macos':
        return '🍎'
      case 'ios':
        return '📱'
      case 'android':
        return '🤖'
      case 'tvos':
        return '📺'
      default:
        return '💻'
    }
  }

  const getStatusColor = (status: string): string => {
    switch (status) {
      case 'connecting':
        return '#f59e0b' // amber
      case 'waiting':
        return '#10b981' // emerald
      case 'reconnecting':
        return '#f97316' // orange
      case 'locked':
        return '#c084fc' // purple
      default:
        return '#6b7280' // gray
    }
  }

  return (
    <div className="waiting-players-panel">
      <div className="panel-header">
        <h3>Available Players</h3>
        <span className="player-count">{players.length}</span>
      </div>

      {error && (
        <div className="error-banner">
          <span>⚠️ {error}</span>
        </div>
      )}

      {loading && players.length === 0 ? (
        <div className="loading-state">
          <div className="spinner" />
          <p>Discovering players...</p>
        </div>
      ) : players.length === 0 ? (
        <div className="empty-state">
          <p>No players available</p>
          <small>Waiting for players to connect via mDNS...</small>
        </div>
      ) : (
        <>
          <div className="players-list">
            {players.map((player) => (
              <label key={player.id} className="player-item">
                <input
                  type="radio"
                  name="player-selection"
                  value={player.id}
                  checked={selectedPlayerId === player.id}
                  onChange={(e) => setSelectedPlayerId(e.target.value)}
                  disabled={selectingPlayerId !== null}
                />
                <div className="player-content">
                  <div className="player-header">
                    <span className="platform-icon">{getPlatformIcon(player.platform)}</span>
                    <span className="player-name">{player.name}</span>
                  </div>
                  <div className="player-meta">
                    <span
                      className="player-status"
                      style={{ color: getStatusColor(player.status) }}
                    >
                      {player.status}
                    </span>
                    <span className="player-platform">{player.platform}</span>
                  </div>
                </div>
                <div className="selection-indicator">
                  {selectedPlayerId === player.id && (
                    <div className="checkmark">✓</div>
                  )}
                </div>
              </label>
            ))}
          </div>

          <div className="players-actions">
            <button
              className="lock-in-button"
              onClick={handleSelectClick}
              disabled={!selectedPlayerId || selectingPlayerId !== null}
            >
              {selectingPlayerId === selectedPlayerId && (
                <span className="button-spinner" />
              )}
              {selectingPlayerId === selectedPlayerId ? 'Locking in...' : 'Lock In Player'}
            </button>
          </div>
        </>
      )}

      <div className="panel-footer">
        <small>Session: {sessionCode}</small>
      </div>
    </div>
  )
}
