import { useState, useEffect } from 'react'
import { usePlayback } from '../hooks/usePlayback'
import { useSessions } from '../hooks/useSessions'
import api from '../services/authService'
import type { Player } from '../types/models'
import { PlayerSelectionModal } from './PlayerSelectionModal'
import './PlaybackPanel.css'

interface PlaybackPanelProps {
  onOpenPlayerDiscovery?: () => void
}

export function PlaybackPanel({ onOpenPlayerDiscovery }: PlaybackPanelProps) {
  const { nowPlaying, availablePlayers, isLoading, selectPlayer, play, pause } =
    usePlayback()
  const { currentSession } = useSessions()
  const [assignedPlayer, setAssignedPlayer] = useState<Player | null>(null)
  const [showPlayerModal, setShowPlayerModal] = useState(false)

  // Fetch assigned player from session on mount and when session changes
  useEffect(() => {
    if (!currentSession?.code) {
      setAssignedPlayer(null)
      return
    }

    const fetchSessionData = async () => {
      try {
        const response = await api.get(`/sessions/${currentSession.code}`)
        const sessionData = response.data
        
        if (sessionData?.player_id && sessionData?.player_name) {
          setAssignedPlayer({
            id: sessionData.player_id,
            name: sessionData.player_name,
            platform: 'unknown',
            status: 'connected' as any,
          })
          console.log('[PlaybackPanel] Assigned player loaded:', sessionData.player_name)
        } else {
          setAssignedPlayer(null)
          console.log('[PlaybackPanel] No assigned player in session')
        }
      } catch (err) {
        console.error('[PlaybackPanel] Failed to fetch session data:', err)
        setAssignedPlayer(null)
      }
    }

    // Fetch immediately on mount
    fetchSessionData()

    // Also poll every 3 seconds to catch updates (player selection, disconnection)
    const pollInterval = setInterval(fetchSessionData, 3000)

    return () => {
      clearInterval(pollInterval)
    }
  }, [currentSession?.code])

  const progressPercent =
    nowPlaying.duration > 0 ? (nowPlaying.elapsed / nowPlaying.duration) * 100 : 0

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  return (
    <div className="playback-panel">
      <div className="playback-header">
        <h3>Now Playing</h3>
      </div>

      <div className="now-playing">
        {nowPlaying.song_id ? (
          <>
            <div className="song-art">♪</div>
            <div className="song-info">
              <div className="song-title">{nowPlaying.title}</div>
              <div className="song-artist">{nowPlaying.artist}</div>
            </div>
          </>
        ) : (
          <div className="no-song">No song selected</div>
        )}
      </div>

      {nowPlaying.song_id && (
        <div className="progress-section">
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${progressPercent}%` }}></div>
          </div>
          <div className="time-display">
            <span>{formatTime(nowPlaying.elapsed)}</span>
            <span>{formatTime(nowPlaying.duration)}</span>
          </div>
        </div>
      )}

      <div className="playback-controls">
        <button className="control-btn prev-btn">⏮</button>
        <button
          className={`control-btn play-btn ${nowPlaying.is_playing ? 'playing' : ''}`}
          onClick={() => (nowPlaying.is_playing ? pause() : play())}
        >
          {nowPlaying.is_playing ? '⏸' : '▶'}
        </button>
        <button className="control-btn next-btn">⏭</button>
      </div>

      <div className="volume-section">
        <span className="volume-icon">🔊</span>
        <input type="range" min="0" max="100" defaultValue="70" className="volume-slider" />
        <span className="volume-label">70%</span>
      </div>

      <div className="player-section">
        <div className="player-info">
          <span className="player-label">Assigned Player:</span>
          <span className="player-name">{assignedPlayer?.name || 'None Selected'}</span>
          {assignedPlayer?.platform && (
            <span className="player-platform">({assignedPlayer.platform})</span>
          )}
        </div>
        <button className="btn-select-player" onClick={() => onOpenPlayerDiscovery?.()}>
          {assignedPlayer ? 'Disconnect' : 'Select Player'}
        </button>
      </div>

      {showPlayerModal && (
        <PlayerSelectionModal
          availablePlayers={availablePlayers}
          assignedPlayer={assignedPlayer}
          onClose={() => setShowPlayerModal(false)}
          onSelectPlayer={selectPlayer}
          isLoading={isLoading}
        />
      )}
    </div>
  )
}
