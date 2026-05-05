import { useCallback, useState } from 'react'
import { Sidebar } from '../components/Sidebar'
import { SessionsPanel } from '../components/SessionsPanel'
import { SessionHeader } from '../components/SessionHeader'
import { PlaybackPanel } from '../components/PlaybackPanel'
import { DownloadsPanel, QueuePanel } from '../components/PlaceholderPanels'
import { SelectPlayerModal } from '../components/SelectPlayerModal'
import { useSessions } from '../hooks/useSessions'
import { usePlayback } from '../hooks/usePlayback'
import './Dashboard.css'

export function DashboardPage() {
  const { sessions, currentSession, selectSession, createSession } = useSessions()
  const { refreshPlayback } = usePlayback()
  const [showPlayerSelection, setShowPlayerSelection] = useState(false)

  // Wrapper to convert Promise<Session> to Promise<void>
  const handleCreateSession = useCallback(
    async (title: string, vibes?: string) => {
      await createSession(title, vibes)
    },
    [createSession]
  )

  if (!currentSession) {
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
        <SessionHeader session={currentSession} />
        <div className="dashboard-panels">
          <div className="panel top-left">
            <PlaybackPanel currentSession={currentSession} onOpenPlayerDiscovery={() => setShowPlayerSelection(true)} />
          </div>
          <div className="panel top-right">
            <DownloadsPanel />
          </div>
          <div className="panel bottom-left">
            <QueuePanel />
          </div>
          <div className="panel bottom-right">
            <div className="placeholder-panel">
              <h3>Players</h3>
              <p>Active players connected to this session will appear here...</p>
            </div>
          </div>
        </div>

        {showPlayerSelection && (
          <SelectPlayerModal
            sessionCode={currentSession.code}
            onClose={() => setShowPlayerSelection(false)}
            onPlayerSelected={refreshPlayback}
          />
        )}
      </main>
    </div>
  )
}
