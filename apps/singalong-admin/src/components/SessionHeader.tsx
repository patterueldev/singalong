import type { Session } from '../types/models'
import './SessionHeader.css'

interface SessionHeaderProps {
  session: Session
}

export function SessionHeader({ session }: SessionHeaderProps) {
  const statusBadge = session.status === 'active' ? '🟢' : '⚪'

  return (
    <header className="session-header">
      <div className="session-info">
        <h2>{session.title}</h2>
        <div className="session-meta">
          <span className="code-badge">Code: {session.code}</span>
          <span className="vibes-badge">{session.vibes || 'Vibes: All'}</span>
          <span className="attendees-badge">👥 {session.user_count} attendees</span>
          <span className={`status-badge ${session.status}`}>
            {statusBadge} {session.status}
          </span>
        </div>
      </div>
      <div className="session-controls">
        <button className="btn btn-secondary">Edit</button>
        {session.status === 'active' && <button className="btn btn-danger">End Session</button>}
      </div>
    </header>
  )
}
