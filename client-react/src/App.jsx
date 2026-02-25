import {
  QueryClient,
  QueryClientProvider,
  useQuery,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query';
import { getMonitors, createMonitor, deleteMonitor } from './api';
import AddMonitorForm from './components/AddMonitorForm';
import MonitorCard from './components/MonitorCard';
import MonitorDetail from './components/MonitorDetail';
import { useState } from 'react';
import './App.css';

const queryClient = new QueryClient();

function Dashboard() {
  const qc = useQueryClient();
  const [selectedId, setSelectedId] = useState(null);

  const { data: monitors, isLoading } = useQuery({
    queryKey: ['monitors'],
    queryFn: getMonitors,
    refetchInterval: 30000,
  });

  const addMutation = useMutation({
    mutationFn: createMonitor,
    onSuccess: () => qc.invalidateQueries(['monitors']),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteMonitor,
    onSuccess: () => {
      qc.invalidateQueries(['monitors']);
      setSelectedId(null);
    },
  });

  if (isLoading) return <p>Loading monitors...</p>;

  return (
    <div className="dashboard">
      <h1>Status Page</h1>
      <AddMonitorForm onSubmit={(data) => addMutation.mutate(data)} />
      <div className="monitor-grid">
        {monitors?.map(m => (
          <MonitorCard
            key={m.id}
            monitor={m}
            onClick={() => setSelectedId(m.id === selectedId ? null : m.id)}
            onDelete={() => deleteMutation.mutate(m.id)}
            isSelected={m.id === selectedId}
          />
        ))}
        {monitors?.length === 0 && (
          <p className="empty-state">No monitors yet. Add one above.</p>
        )}
      </div>
      {selectedId && <MonitorDetail monitorId={selectedId} />}
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Dashboard />
    </QueryClientProvider>
  );
}
