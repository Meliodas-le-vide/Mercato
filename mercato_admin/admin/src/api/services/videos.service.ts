import apiClient from '../client';

export interface Video {
  id: number;
  title: string;
  description?: string;
  videoUrl: string;
  thumbnailUrl?: string;
  viewsCount: number;
  likesCount: number;
  commentsCount: number;
  position?: string;
  createdAt: string;
  author: {
    id: number;
    firstname: string;
    lastname: string;
    Profile_image?: string;
  };
}

export const videosService = {
  async getAll(page = 1, limit = 20) {
    const { data } = await apiClient.get('/admin/videos', {
      params: { page, limit },
    });
    return data;
  },

  async delete(id: number): Promise<void> {
    await apiClient.delete(`/admin/videos/${id}`);
  },
};