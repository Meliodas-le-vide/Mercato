import apiClient from '../client';

export interface User {
  id: number;
  firstname: string;
  lastname: string;
  email: string;
  phone?: string;
  role: string;
  Profile_image?: string;
  isBanned: boolean;
  createdAt: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const usersService = {
  async getAll(
    page = 1,
    limit = 20,
    role?: string,
    search?: string
  ): Promise<PaginatedResponse<User>> {
    const { data } = await apiClient.get('/admin/users', {
      params: { page, limit, role, search },
    });
    return data;
  },

  async ban(id: number, reason: string): Promise<void> {
    await apiClient.patch(`/admin/users/${id}/ban`, { banned: true, reason });
  },

  async unban(id: number): Promise<void> {
    await apiClient.patch(`/admin/users/${id}/ban`, { banned: false });
  },

  async delete(id: number): Promise<void> {
    await apiClient.delete(`/admin/users/${id}`);
  },
};