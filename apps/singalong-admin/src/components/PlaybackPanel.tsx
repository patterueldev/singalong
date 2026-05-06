import { useState } from 'react'
import Swal from 'sweetalert2'
import { usePlayback } from '../hooks/usePlayback'
import { useSessions } from '../hooks/useSessions'
import api from '../services/authService'
import { PlayerSelectionModal } from './PlayerSelectionModal'
import './PlaybackPanel.css'

interface PlaybackPanelProps {
  onOpenPlayerDiscovery?: () => void
  playbackState?: ReturnType<typeof usePlayback>
}

export function PlaybackPanel({ onOpenPlayerDiscovery, playbackState }: PlaybackPanelProps) {
  const defaultPlaybackState = usePlayback()
  // Use passed state or fall back to local hook (for standalone usage)
  const { nowPlaying, availablePlayers, assignedPlayer, isLoading, selectPlayer, refreshPlayback, play, pause } =
    playbackState || defaultPlaybackState
  const { currentSession } = useSessions()
  const [isDisconnecting, setIsDisconnecting] = useState(false)

  const formatPlayerId = (id: string): string => {
    if (id.length <= 12) return id
    return `${id.substring(0, 8)}...${id.substring(id.length - 4)}`
  }

  const handlePlayerButton = () => {
    if (assignedPlayer) {
      handleDisconnectClick()
    } else {
      onOpenPlayerDiscovery?.()
    }
  }

  const handleDisconnectClick = async () => {
    if (!assignedPlayer || !currentSession?.code) return

    const result = await Swal.fire({
      title: 'Disconnect Player?',
      html: `<strong>${assignedPlayer.name}</strong> will be disconnected from this session and returned to discovery mode.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c084fc',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Yes, disconnect',
      cancelButtonText: 'Cancel',
    })

    if (!result.isConfirmed) return

    setIsDisconnecting(true)
    try {
      await api.post(`/sessions/${currentSession.code}/disconnect-player`)
      console.log('[PlaybackPanel] Player disconnected successfully')
      
      // Show success message
      await Swal.fire({
        title: 'Disconnected!',
        text: `${assignedPlayer.name} has been disconnected. Select a new player when ready.`,
        icon: 'success',
        confirmButtonColor: '#c084fc',
      })
      
      // Refresh to clear assigned player from UI
      await refreshPlayback()
      // Automatically open player selection to show discovery is re-enabled
      onOpenPlayerDiscovery?.()
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to disconnect player'
      console.error('[PlaybackPanel] Disconnect error:', errorMsg)
      
      await Swal.fire({
        title: 'Disconnection Failed',
        text: errorMsg,
        icon: 'error',
        confirmButtonColor: '#c084fc',
      })
    } finally {
      setIsDisconnecting(false)
    }
  }

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
          {assignedPlayer?.id && (
            <span className="player-id">ID: {formatPlayerId(assignedPlayer.id)}</span>
          )}
        </div>
        <button 
          className="btn-select-player" 
          onClick={handlePlayerButton}
          disabled={isDisconnecting}
        >
          {isDisconnecting ? 'Disconnecting...' : (assignedPlayer ? 'Disconnect' : 'Select Player')}
        </button>
      </div>
    </div>
  )
}
