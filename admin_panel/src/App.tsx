import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './store/authStore';
import AdminLayout from './components/layout/AdminLayout';
import LoginPage from './pages/auth/LoginPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import SalonsPage from './pages/salons/SalonsPage';
import SalonFormPage from './pages/salons/SalonFormPage';
import BarbersPage from './pages/barbers/BarbersPage';
import CustomersPage from './pages/customers/CustomersPage';
import BookingsPage from './pages/bookings/BookingsPage';
import CategoriesPage from './pages/categories/CategoriesPage';
import RegionsPage from './pages/regions/RegionsPage';
import NotificationsPage from './pages/notifications/NotificationsPage';
import ReportsPage from './pages/reports/ReportsPage';
import BannersPage from './pages/banners/BannersPage';
import SettingsPage from './pages/settings/SettingsPage';
import PortfolioPage from './pages/portfolio/PortfolioPage';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuthStore();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  const { isAuthenticated } = useAuthStore();

  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />}
      />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="salons" element={<SalonsPage />} />
        <Route path="salons/new" element={<SalonFormPage />} />
        <Route path="salons/:id/edit" element={<SalonFormPage />} />
        <Route path="barbers" element={<BarbersPage />} />
        <Route path="customers" element={<CustomersPage />} />
        <Route path="bookings" element={<BookingsPage />} />
        <Route path="categories" element={<CategoriesPage />} />
        <Route path="regions" element={<RegionsPage />} />
        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="portfolio" element={<PortfolioPage />} />
        <Route path="banners" element={<BannersPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
