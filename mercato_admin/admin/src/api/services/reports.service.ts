import apiClient from '../client';

export interface Report {
  id: number;
  reason: string;
  details?: string;
  status: 'OPEN' | 'REVIEWED' | 'DISMISSED';
  createdAt: string;
  reporter: {
    id: number;
    firstname: string;
    lastname: string;
    email: string;
  };
  target: {
    id: number;
    firstname: string;
    lastname: string;
    email: string;
    role: string;
  };
}

export const reportsService = {
  async getAll(status?: string): Promise<Report[]> {
    const { data } = await apiClient.get('/admin/reports', {
      params: { status },
    });
    return data.data;
  },

  async review(id: number, status: 'REVIEWED' | 'DISMISSED'): Promise<void> {
    await apiClient.patch(`/admin/reports/${id}`, { status });
  },
};