import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { LoginPage } from './pages/Login'
import { DashboardPage } from './pages/Dashboard'
import { ProtectedRoute } from './components/ProtectedRoute'
import './App.css'

// Get basename from environment: use /admin/ for production builds, / for dev
// In production, import.meta.env.BASE_URL will be '/admin/'
// In dev, Vite serves from root so it's '/'
const basename = import.meta.env.BASE_URL.endsWith('/') 
  ? import.meta.env.BASE_URL.slice(0, -1) 
  : import.meta.env.BASE_URL

function App() {
  return (
    <Router basename={basename}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Router>
  )
}

export default App
