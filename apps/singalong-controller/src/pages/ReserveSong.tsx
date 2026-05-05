import { useState } from 'react';
import { useApi } from '../hooks/useApi';

interface ReservationRequest {
  songId: string;
  performerName: string;
  date?: string;
}

export function ReserveSong() {
  const [formData, setFormData] = useState<ReservationRequest>({
    songId: '',
    performerName: '',
    date: '',
  });
  const { loading, error, request } = useApi<{ success: boolean; message: string }>();
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await request('post', '/reservations', formData);
      setSuccess(true);
      setFormData({ songId: '', performerName: '', date: '' });
      setTimeout(() => setSuccess(false), 5000);
    } catch {
      // Error is handled by useApi hook
    }
  };

  return (
    <div>
      <h1>Reserve a Song</h1>
      <p>Reserve a song for your upcoming performance.</p>
      
      {success && <p style={{ color: 'green' }}>✓ Song reserved successfully!</p>}
      {error && <p style={{ color: 'red' }}>✗ Error reserving song. Please try again.</p>}

      <form onSubmit={handleSubmit}>
        <div>
          <label>
            Song ID:
            <input
              type="text"
              value={formData.songId}
              onChange={(e) => setFormData({ ...formData, songId: e.target.value })}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Performer Name:
            <input
              type="text"
              value={formData.performerName}
              onChange={(e) => setFormData({ ...formData, performerName: e.target.value })}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Date (optional):
            <input
              type="date"
              value={formData.date || ''}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
            />
          </label>
        </div>
        <button type="submit" disabled={loading}>
          {loading ? 'Reserving...' : 'Reserve Song'}
        </button>
      </form>
    </div>
  );
}

export default ReserveSong;
