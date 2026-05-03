import type { Player } from '../types/models'
import './Modals.css'

interface PlayerSelectionModalProps {
  availablePlayers: Player[]
  assignedPlayer: Player | null
  onClose: () => void
}

export function PlayerSelectionModal({
  availablePlayers,
  onClose,
}: PlayerSelectionModalProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Select Player</h3>
          <button className="modal-close" onClick={onClose}>
            ✕
          </button>
        </div>

        <div className="modal-body">
          {availablePlayers.length === 0 ? (
            <div className="empty-state">
              <p>No players available yet.</p>
              <p style={{ fontSize: '12px', color: '#6b7280' }}>
                Players will appear here when they connect to the network.
              </p>
            </div>
          ) : (
            <div className="player-list">
              {availablePlayers.map((player) => (
                <div key={player.id} className="player-item">
                  <div className="player-details">
                    <div className="player-name-modal">{player.name}</div>
                    <div className="player-status" data-status={player.status}>
                      {player.status}
                    </div>
                  </div>
                  <button className="player-select-btn">Select</button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn-cancel" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  )
}
