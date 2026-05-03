import { useState } from 'react'
import { useSessions } from '../hooks/useSessions'
import type { Session } from '../types/models'
import { CreateSessionModal } from './CreateSessionModal'
import './SessionsPanel.css'

interface SessionsPanelProps {
  sessions: Session[]
}

export function SessionsPanel({ sessions }: SessionsPanelProps) {
  const { selectSession } = useSessions()
  const [showCreateModal, setShowCreateModal] = useState(false)

  const handleSelectSession = async (code: string) => {
    await selectSession(code)
  }

  return (
    <div className="sessions-panel">
      <div className="sessions-header">
        <h2>Sessions</h2>
        <button className="btn btn-primary" onClick={() => setShowCreateModal(true)}>
          + Create Session
        </button>
      </div>

      {sessions.length === 0 ? (
        <div className="empty-sessions">
          <p>No sessions yet. Create one to get started!</p>
        </div>
      ) : (
        <div className="sessions-list">
          {sessions.map((session) => (
            <div key={session.code} className="session-card">
              <div className="session-card-info">
                <h3>{session.title}</h3>
                <p>{session.vibes || 'No vibes'}</p>
                <span className={`status ${session.status}`}>{session.status}</span>
              </div>
              <div className="session-card-meta">
                <span>{session.user_count} attendees</span>
              </div>
              <button
                className="btn btn-primary"
                onClick={() => handleSelectSession(session.code)}
              >
                Select
              </button>
            </div>
          ))}
        </div>
      )}

      {showCreateModal && <CreateSessionModal onClose={() => setShowCreateModal(false)} />}
    </div>
  )
}
