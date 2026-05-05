import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import SongBook from './pages/SongBook';
import ReserveSong from './pages/ReserveSong';
import SearchSongs from './pages/SearchSongs';
import MakeSuggestion from './pages/MakeSuggestion';
import './App.css';

function App() {
  return (
    <Router basename="/controller">
      <div className="app">
        <nav className="navbar">
          <h1>{import.meta.env.VITE_APP_TITLE || 'Singalong Controller'}</h1>
          <ul>
            <li><Link to="/">Song Book</Link></li>
            <li><Link to="/reserve">Reserve</Link></li>
            <li><Link to="/search">Search</Link></li>
            <li><Link to="/suggest">Suggest</Link></li>
          </ul>
        </nav>
        
        <main className="main-content">
          <Routes>
            <Route path="/" element={<SongBook />} />
            <Route path="/reserve" element={<ReserveSong />} />
            <Route path="/search" element={<SearchSongs />} />
            <Route path="/suggest" element={<MakeSuggestion />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
