export const Header = () => {
  return (
    <header className="app-header">
      <div className="header-content">
        <h1>Singalong Admin</h1>
        <nav className="header-nav">
          <a href="/">Dashboard</a>
          <a href="/songs">Songs</a>
          <a href="/reserves">Reservations</a>
          <a href="/settings">Settings</a>
        </nav>
      </div>
    </header>
  )
}
