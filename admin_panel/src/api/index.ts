import api from './client';

export const authAPI = {
  sendOTP: (phone: string) => api.post('/auth/send-otp/', { phone }),
  verifyOTP: (phone: string, code: string) => api.post('/auth/verify-otp/', { phone, code }),
  logout: (refresh: string) => api.post('/auth/logout/', { refresh }),
};

export const dashboardAPI = {
  getStats: () => api.get('/analytics/admin/dashboard/'),
};

export const salonsAPI = {
  list: (params?: object) => api.get('/salons/admin/salons/', { params }),
  get: (id: number) => api.get(`/salons/admin/salons/${id}/`),
  create: (data: FormData) => api.post('/salons/admin/salons/', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  update: (id: number, data: FormData) => api.patch(`/salons/admin/salons/${id}/`, data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  delete: (id: number) => api.delete(`/salons/admin/salons/${id}/`),
};

export const barbersAPI = {
  list: (params?: object) => api.get('/barbers/admin/list/', { params }),
  verify: (id: number, action: 'approve' | 'reject', reason?: string) =>
    api.post(`/barbers/admin/${id}/verify/`, { action, reason }),
  update: (id: number, data: object) => api.patch(`/barbers/admin/${id}/update/`, data),
  delete: (id: number) => api.delete(`/barbers/admin/${id}/delete/`),
  portfolioList: (id: number) => api.get(`/barbers/admin/${id}/portfolio/`),
  portfolioAdd: (id: number, afterFile: File, beforeFile?: File | null, caption?: string) => {
    const fd = new FormData();
    fd.append('after_image', afterFile);
    if (beforeFile) fd.append('before_image', beforeFile);
    if (caption) fd.append('caption', caption);
    return api.post(`/barbers/admin/${id}/portfolio/`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
  },
  portfolioDelete: (barberId: number, itemId: number) => api.delete(`/barbers/admin/${barberId}/portfolio/${itemId}/`),
  portfolioApprove: (barberId: number, itemId: number) => api.patch(`/barbers/admin/${barberId}/portfolio/${itemId}/`, { action: 'approve' }),
  portfolioReject: (barberId: number, itemId: number, reason: string) => api.patch(`/barbers/admin/${barberId}/portfolio/${itemId}/`, { action: 'reject', reason }),
  pendingPortfolio: () => api.get('/barbers/admin/portfolio/pending/'),
};

export const categoriesAPI = {
  list: () => api.get('/salons/admin/categories/'),
  create: (data: FormData) => api.post('/salons/admin/categories/', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  update: (id: number, data: FormData) => api.patch(`/salons/admin/categories/${id}/`, data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  delete: (id: number) => api.delete(`/salons/admin/categories/${id}/`),
};

export const bookingsAPI = {
  list: (params?: object) => api.get('/bookings/admin/list/', { params }),
};

export const usersAPI = {
  list: (params?: object) => api.get('/users/admin/list/', { params }),
};

export const notificationsAPI = {
  broadcast: (data: object) => api.post('/notifications/broadcast/', data),
};

export const bannersAPI = {
  list: () => api.get('/salons/admin/banners/'),
  create: (data: FormData) => api.post('/salons/admin/banners/', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  update: (id: number, data: FormData) => api.patch(`/salons/admin/banners/${id}/`, data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  delete: (id: number) => api.delete(`/salons/admin/banners/${id}/`),
};

export const regionsAPI = {
  list: () => api.get('/users/regions/'),
  districts: (regionId?: number) => api.get('/users/districts/', { params: regionId ? { region: regionId } : {} }),
};

export const workingHoursAPI = {
  get: (salonId: number) => api.get(`/salons/admin/salons/${salonId}/working-hours/`),
  set: (salonId: number, data: object[]) => api.put(`/salons/admin/salons/${salonId}/working-hours/`, data),
};

export const salonImagesAPI = {
  list: (salonId: number) => api.get(`/salons/admin/salons/${salonId}/images/`),
  upload: (salonId: number, file: File) => {
    const fd = new FormData();
    fd.append('image', file);
    return api.post(`/salons/admin/salons/${salonId}/images/`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
  },
  delete: (salonId: number, imgId: number) => api.delete(`/salons/admin/salons/${salonId}/images/${imgId}/`),
};
