import { useCallback } from 'react'
import { Sidebar } from '../components/Sidebar'
import { SessionsPanel } from '../components/SessionsPanel'
import { SessionHeader } from '../components/SessionHeader'
import { PlaybackPanel } from '../components/PlaybackPanel'
import { DownloadsPanel, QueuePanel, AttendeesPanel } from '../components/PlaceholderPanels'
import { useSessions } from '../hooks/useSessions'
import './Dashboard.css'

export function DashboardPage() {
  const { sessions, currentSession, selectSession, createSession } = useSessions()

  // Wrapper to convert Promise<Session> to Promise<void>
  const handleCreateSession = useCallback(
    async (title: string, vibes?: string) => {
      await createSession(title, vibes)
    },
    [createSession]
  )

  if (!currentSession && (!sessions || sessions.length === 0)) {
    return (
      <div className="dashboard-container">
        <Sidebar />
        <main className="dashboard-main">
          <SessionsPanel
            sessions={sessions || []}
            onSelectSession={selectSession}
            onCreateSession={handleCreateSession}
          />
        </main>
      </div>
    )
  }

  return (
    <div className="dashboard-container">
      <Sidebar />
      <main className="dashboard-main">
      <>
            <SessionHeader session={currentSession} />
            <div className="dashboard-panels">
              <div className="panel top-left">
                <PlaybackPanel />
              </div>
              <div className="panel top-right">
                <DownloadsPanel />
              </div>
              <div className="panel bottom-left">
                <QueuePanel />
              </div>
              <div className="panel bottom-right">
                <AttendeesPanel />
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  )
}
      </main>
    </div>
  )
}
