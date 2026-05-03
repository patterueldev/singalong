import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import './Sidebar.css'

export function Sidebar() {
  const navigate = useNavigate()
  const { logout } = useAuth()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <h2>Singalong</h2>
        <p>Admin</p>
      </div>

      <nav className="sidebar-nav">
        <a href="#sessions" className="nav-item active">
          <span>Sessions</span>
        </a>
        <a href="#players" className="nav-item">
          <span>Players</span>
        </a>
        <a href="#settings" className="nav-item">
          <span>Settings</span>
        </a>
      </nav>

      <div className="sidebar-footer">
        <div className="status-indicator">
          <span className="status-dot online"></span>
          <span>Connected</span>
        </div>
        <button onClick={handleLogout} className="logout-btn">
          Logout
        </button>
      </div>
    </aside>
  )
}
