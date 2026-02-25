import { useState } from 'react';

export default function AddMonitorForm({ onSubmit }) {
  const [name, setName] = useState('');
  const [url, setUrl] = useState('');
  const [interval, setInterval] = useState(60);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name || !url) return;
    onSubmit({ name, url, interval_seconds: Number(interval) });
    setName('');
    setUrl('');
    setInterval(60);
  };

  return (
    <form onSubmit={handleSubmit} className="add-form">
      <input
        placeholder="Name (e.g. Google)"
        value={name}
        onChange={e => setName(e.target.value)}
        required
      />
      <input
        placeholder="https://google.com"
        value={url}
        onChange={e => setUrl(e.target.value)}
        required
        type="url"
      />
      <input
        type="number"
        min="10"
        max="3600"
        value={interval}
        onChange={e => setInterval(e.target.value)}
        title="Check interval (seconds)"
      />
      <button type="submit">Add Monitor</button>
    </form>
  );
}
