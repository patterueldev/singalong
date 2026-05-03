import { Sidebar } from '../components/Sidebar'
import { SessionsPanel } from '../components/SessionsPanel'
import { SessionHeader } from '../components/SessionHeader'
import { PlaybackPanel } from '../components/PlaybackPanel'
import { DownloadsPanel, QueuePanel, AttendeesPanel } from '../components/PlaceholderPanels'
import { useSessions } from '../hooks/useSessions'
import './Dashboard.css'

export function DashboardPage() {
  const { sessions, currentSession, selectSession } = useSessions()

  if (!currentSession && sessions.length === 0) {
    return (
      <div className="dashboard-container">
        <Sidebar />
        <main className="dashboard-main">
          <SessionsPanel sessions={sessions} onSelectSession={selectSession} />
        </main>
      </div>
    )
  }

  return (
    <div className="dashboard-container">
      <Sidebar />
      <main className="dashboard-main">
        {!currentSession ? (
          <SessionsPanel sessions={sessions} onSelectSession={selectSession} />
        ) : (
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
