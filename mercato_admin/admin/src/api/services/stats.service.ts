import apiClient from '../client';

export interface DashboardStats {
  totalPlayers: number;
  totalRecruiters: number;
  totalVideos: number;
  totalReports: number;
  pendingKyc: number;
  upcomingEvents: number;
}

export interface ChartData {
  labels: string[];
  values: number[];
}

export const statsService = {
  async getDashboardStats(): Promise<DashboardStats> {
    const { data } = await apiClient.get('/admin/stats');
    return data.data;
  },

  async getViewsChart(period = '30d'): Promise<ChartData> {
    const { data } = await apiClient.get('/admin/stats/views-chart', {
      params: { period },
    });
    return data.data;
  },
};