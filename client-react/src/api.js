import axios from 'axios';

const API = '/api/node';

export const getMonitors = () =>
  axios.get(`${API}/monitors`).then(res => res.data);

export const createMonitor = (data) =>
  axios.post(`${API}/monitors`, data).then(res => res.data);

export const deleteMonitor = (id) =>
  axios.delete(`${API}/monitors/${id}`);

export const getChecks = (monitorId) =>
  axios.get(`${API}/checks/${monitorId}`).then(res => res.data);
