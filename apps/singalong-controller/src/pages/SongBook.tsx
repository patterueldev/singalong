import { useEffect } from 'react';
import { useApi } from '../hooks/useApi';

interface Song {
  id: string;
  title: string;
  artist: string;
  genre?: string;
}

export function SongBook() {
  const { data: songs, loading, error, request } = useApi<Song[]>();

  useEffect(() => {
    request('get', '/songs');
  }, [request]);

  if (loading) return <div><p>Loading songs...</p></div>;
  if (error) {
    return (
      <div>
        <p>Error loading songs. Please try again.</p>
        <p style={{ fontSize: '0.9em', color: '#666' }}>
          {error.message}
        </p>
      </div>
    );
  }

  return (
    <div>
      <h1>Song Book</h1>
      <p>Browse and explore our collection of songs.</p>
      {Array.isArray(songs) && songs.length > 0 ? (
        <ul>
          {songs.map((song) => (
            <li key={song.id}>
              <strong>{song.title}</strong> by {song.artist}
              {song.genre && <span> - {song.genre}</span>}
            </li>
          ))}
        </ul>
      ) : (
        <p>No songs found.</p>
      )}
    </div>
  );
}

export default SongBook;

