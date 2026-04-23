import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import './App.css'

function App() {
  return (
    <Router>
      <div className="app">
        <header className="app-header">
          <h1>Singalong Admin</h1>
          <p>Node Management & Song Control</p>
        </header>
        <main className="app-main">
          <Routes>
            <Route path="/" element={<div>Welcome to Singalong Admin</div>} />
          </Routes>
        </main>
      </div>
    </Router>
  )
}

export default App
