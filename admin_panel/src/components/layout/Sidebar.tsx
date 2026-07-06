import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Store, Scissors, Users, CalendarCheck,
  Tag, MapPin, Bell, Image, BarChart3, Settings,
  ChevronLeft, ChevronRight, Sparkles, LogOut, GalleryHorizontal,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuthStore } from '../../store/authStore';
import { authAPI } from '../../api';
import toast from 'react-hot-toast';
import clsx from 'clsx';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard', end: true },
  { to: '/salons', icon: Store, label: 'Salonlar' },
  { to: '/barbers', icon: Scissors, label: 'Sartaroshlar' },
  { to: '/portfolio', icon: GalleryHorizontal, label: 'Portfolio' },
  { to: '/customers', icon: Users, label: 'Mijozlar' },
  { to: '/bookings', icon: CalendarCheck, label: 'Bronlar' },
  { to: '/categories', icon: Tag, label: 'Kategoriyalar' },
  { to: '/regions', icon: MapPin, label: 'Hududlar' },
  { to: '/banners', icon: Image, label: 'Bannerlar' },
  { to: '/notifications', icon: Bell, label: 'Bildirishnomalar' },
  { to: '/reports', icon: BarChart3, label: 'Hisobotlar' },
  { to: '/settings', icon: Settings, label: 'Sozlamalar' },
];

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export default function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      const refresh = localStorage.getItem('refresh_token');
      if (refresh) await authAPI.logout(refresh);
    } catch { /* silent */ }
    logout();
    navigate('/login');
    toast.success('Chiqildi');
  };

  return (
    <motion.aside
      animate={{ width: collapsed ? 72 : 256 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className="bg-white border-r border-gray-200 flex flex-col flex-shrink-0 overflow-hidden relative z-10 shadow-sm"
    >
      {/* Logo */}
      <div className="h-16 flex items-center px-4 border-b border-gray-100 flex-shrink-0">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center flex-shrink-0 shadow-sm">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
          <AnimatePresence>
            {!collapsed && (
              <motion.div
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -10 }}
                className="flex flex-col min-w-0"
              >
                <span className="font-display font-bold text-gray-900 text-lg leading-none">StilTime</span>
                <span className="text-xs text-primary-600 font-medium">SuperAdmin</span>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 py-4 px-2 space-y-0.5 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              clsx(
                'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200',
                isActive
                  ? 'bg-primary-50 text-primary-700 border border-primary-200'
                  : 'text-gray-500 hover:text-gray-900 hover:bg-gray-100'
              )
            }
          >
            <Icon className="w-5 h-5 flex-shrink-0" />
            <AnimatePresence>
              {!collapsed && (
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="truncate"
                >
                  {label}
                </motion.span>
              )}
            </AnimatePresence>
          </NavLink>
        ))}
      </nav>

      {/* User + Logout */}
      <div className="p-2 border-t border-gray-100 space-y-0.5">
        <div className={clsx('flex items-center gap-3 px-3 py-2.5 rounded-xl', collapsed && 'justify-center')}>
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center flex-shrink-0 text-white text-xs font-bold shadow-sm">
            {user?.full_name?.[0] || 'A'}
          </div>
          <AnimatePresence>
            {!collapsed && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="min-w-0">
                <p className="text-sm font-semibold text-gray-800 truncate">{user?.full_name || 'Admin'}</p>
                <p className="text-xs text-gray-400 truncate">{user?.phone}</p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-red-500 hover:text-red-700 hover:bg-red-50 transition-all duration-200"
        >
          <LogOut className="w-5 h-5 flex-shrink-0" />
          <AnimatePresence>
            {!collapsed && (
              <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                Chiqish
              </motion.span>
            )}
          </AnimatePresence>
        </button>
      </div>

      {/* Toggle button */}
      <button
        onClick={onToggle}
        className="absolute top-1/2 -right-3.5 w-7 h-7 bg-white border border-gray-200 rounded-full flex items-center justify-center text-gray-400 hover:text-primary-600 hover:border-primary-300 transition-all duration-200 shadow-md"
      >
        {collapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
      </button>
    </motion.aside>
  );
}
