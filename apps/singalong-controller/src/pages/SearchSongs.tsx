import { useState, useEffect } from 'react';
import { useApi } from '../hooks/useApi';

interface Song {
  id: string;
  title: string;
  artist: string;
  genre?: string;
}

export function SearchSongs() {
  const [query, setQuery] = useState('');
  const [searchResults, setSearchResults] = useState<Song[]>([]);
  const { data: results, loading, error, request } = useApi<Song[]>();

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (query.trim()) {
      await request('get', `/songs/search?q=${encodeURIComponent(query)}`);
    }
  };

  useEffect(() => {
    if (results) {
      setSearchResults(results);
    }
  }, [results]);

  return (
    <div>
      <h1>Search Songs</h1>
      <p>Find songs by title, artist, or genre.</p>

      <form onSubmit={handleSearch}>
        <div>
          <input
            type="text"
            placeholder="Search by title, artist, or genre..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Searching...' : 'Search'}
          </button>
        </div>
      </form>

      {error && <p style={{ color: 'red' }}>✗ Error searching songs.</p>}

      {searchResults.length > 0 ? (
        <div>
          <p>Found {searchResults.length} song(s)</p>
          <ul>
            {searchResults.map((song) => (
              <li key={song.id}>
                <strong>{song.title}</strong> by {song.artist}
                {song.genre && <span> - {song.genre}</span>}
              </li>
            ))}
          </ul>
        </div>
      ) : (
        query && <p>No songs found matching "{query}"</p>
      )}
    </div>
  );
}

export default SearchSongs;
