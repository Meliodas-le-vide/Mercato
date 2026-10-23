import axios, { type AxiosInstance, type AxiosError } from 'axios';
export const API_BASE_URL =
  import.meta.env.VITE_API_URL ?? 'http://localhost:5000/api/v1';

const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

// -----------------------------------------------------------------------------
// Intercepteur requêtes → ajoute le token
// -----------------------------------------------------------------------------
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// -----------------------------------------------------------------------------
// Intercepteur réponses → gère le 401
// -----------------------------------------------------------------------------
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// -----------------------------------------------------------------------------
// Helper d'erreur
// -----------------------------------------------------------------------------
export function getErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as
      | { message?: string; error?: string }
      | undefined;
    return data?.message || data?.error || error.message || 'Erreur inconnue';
  }
  if (error instanceof Error) return error.message;
  return 'Erreur inconnue';
}

export default apiClient;