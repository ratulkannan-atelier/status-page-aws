export default function MonitorCard({ monitor, onClick, onDelete, isSelected }) {
  const isUp = monitor.last_is_up;
  const statusColor = isUp === null ? '#888' : isUp ? '#4caf50' : '#f44336';
  const statusText = isUp === null ? 'Pending' : isUp ? 'Up' : 'Down';

  return (
    <div
      className={`monitor-card ${isSelected ? 'selected' : ''}`}
      onClick={onClick}
    >
      <div className="status-indicator" style={{ backgroundColor: statusColor }} />
      <div className="monitor-info">
        <strong>{monitor.name}</strong>
        <span className="monitor-url">{monitor.url}</span>
        <span className="monitor-status">
          {statusText}
          {monitor.last_response_time_ms != null && ` - ${monitor.last_response_time_ms}ms`}
        </span>
      </div>
      <button
        className="delete-btn"
        onClick={(e) => { e.stopPropagation(); onDelete(); }}
      >
        X
      </button>
    </div>
  );
}
