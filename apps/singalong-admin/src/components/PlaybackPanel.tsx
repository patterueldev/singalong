import { useState } from 'react'
import { usePlayback } from '../hooks/usePlayback'
import { PlayerSelectionModal } from './PlayerSelectionModal'
import './PlaybackPanel.css'

export function PlaybackPanel() {
  const { nowPlaying, assignedPlayer, availablePlayers, isLoading, selectPlayer, play, pause } =
    usePlayback()
  const [showPlayerModal, setShowPlayerModal] = useState(false)

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
        <button className="btn-select-player" onClick={() => setShowPlayerModal(true)}>
          {assignedPlayer ? 'Change Player' : 'Select Player'}
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
