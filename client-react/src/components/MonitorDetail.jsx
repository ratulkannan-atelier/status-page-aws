import { useQuery } from '@tanstack/react-query';
import { getChecks } from '../api';

export default function MonitorDetail({ monitorId }) {
  const { data, isLoading } = useQuery({
    queryKey: ['checks', monitorId],
    queryFn: () => getChecks(monitorId),
    refetchInterval: 30000,
  });

  if (isLoading) return <p>Loading check history...</p>;
  if (!data || data.checks.length === 0) return <p>No checks yet. Waiting for first ping...</p>;

  const maxTime = Math.max(...data.checks.map(c => c.response_time_ms || 0), 1);

  return (
    <div className="monitor-detail">
      <h3>Uptime (24h): {data.uptime_percentage ?? 'N/A'}%</h3>
      <div className="check-history">
        {data.checks.slice().reverse().map(check => (
          <div
            key={check.id}
            className="check-bar"
            title={`${check.response_time_ms}ms - ${new Date(check.checked_at).toLocaleTimeString()}`}
          >
            <div
              className="bar-fill"
              style={{
                height: `${((check.response_time_ms || 0) / maxTime) * 100}%`,
                backgroundColor: check.is_up ? '#4caf50' : '#f44336',
              }}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
