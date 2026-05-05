import { useState } from 'react';
import { useApi } from '../hooks/useApi';

interface SuggestionRequest {
  songTitle: string;
  artist: string;
  genre?: string;
  suggestedBy: string;
  comment?: string;
}

export function MakeSuggestion() {
  const [formData, setFormData] = useState<SuggestionRequest>({
    songTitle: '',
    artist: '',
    genre: '',
    suggestedBy: '',
    comment: '',
  });
  const { loading, error, request } = useApi<{ success: boolean; message: string }>();
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await request('post', '/suggestions', formData);
      setSuccess(true);
      setFormData({
        songTitle: '',
        artist: '',
        genre: '',
        suggestedBy: '',
        comment: '',
      });
      setTimeout(() => setSuccess(false), 5000);
    } catch {
      // Error is handled by useApi hook
    }
  };

  return (
    <div>
      <h1>Make a Suggestion</h1>
      <p>Suggest a new song to add to our collection.</p>

      {success && <p style={{ color: 'green' }}>✓ Suggestion submitted successfully!</p>}
      {error && <p style={{ color: 'red' }}>✗ Error submitting suggestion. Please try again.</p>}

      <form onSubmit={handleSubmit}>
        <div>
          <label>
            Song Title:
            <input
              type="text"
              value={formData.songTitle}
              onChange={(e) => setFormData({ ...formData, songTitle: e.target.value })}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Artist:
            <input
              type="text"
              value={formData.artist}
              onChange={(e) => setFormData({ ...formData, artist: e.target.value })}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Genre (optional):
            <input
              type="text"
              value={formData.genre || ''}
              onChange={(e) => setFormData({ ...formData, genre: e.target.value })}
            />
          </label>
        </div>
        <div>
          <label>
            Your Name:
            <input
              type="text"
              value={formData.suggestedBy}
              onChange={(e) => setFormData({ ...formData, suggestedBy: e.target.value })}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Comment (optional):
            <textarea
              value={formData.comment || ''}
              onChange={(e) => setFormData({ ...formData, comment: e.target.value })}
              rows={4}
            />
          </label>
        </div>
        <button type="submit" disabled={loading}>
          {loading ? 'Submitting...' : 'Submit Suggestion'}
        </button>
      </form>
    </div>
  );
}

export default MakeSuggestion;
