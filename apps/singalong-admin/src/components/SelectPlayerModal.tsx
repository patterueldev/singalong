import { useState } from 'react'
import { useAvailablePlayers } from '../hooks/useAvailablePlayers'
import '../styles/SelectPlayerModal.css'

interface SelectPlayerModalProps {
  sessionCode: string
  onClose: () => void
  onPlayerSelected?: () => Promise<void>
  isOpen?: boolean
}

export function SelectPlayerModal({ sessionCode, onClose, onPlayerSelected, isOpen = true }: SelectPlayerModalProps) {
  console.log('[SelectPlayerModal] Rendering with isOpen:', isOpen)
  const { players, loading, error, selectPlayer, selectingPlayerId } = useAvailablePlayers(isOpen)
  const [selectedPlayerId, setSelectedPlayerId] = useState<string | null>(null)

  const handleSelectClick = async () => {
    if (!selectedPlayerId) return
    try {
      await selectPlayer(selectedPlayerId, sessionCode)
      setSelectedPlayerId(null)
      // Trigger playback state refresh
      if (onPlayerSelected) {
        await onPlayerSelected()
      }
      onClose()
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
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Select Player for Session {sessionCode}</h2>
          <button className="modal-close" onClick={onClose}>
            ✕
          </button>
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

            <div className="modal-footer">
              <button
                className="cancel-button"
                onClick={onClose}
                disabled={selectingPlayerId !== null}
              >
                Cancel
              </button>
              <button
                className="lock-in-button"
                onClick={handleSelectClick}
                disabled={!selectedPlayerId || selectingPlayerId !== null}
              >
                {selectingPlayerId !== null && (
                  <span className="button-spinner" />
                )}
                {selectingPlayerId !== null ? 'Locking in...' : 'Lock In Player'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
