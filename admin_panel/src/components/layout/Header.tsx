import { Bell, Search } from 'lucide-react';
import { useLocation } from 'react-router-dom';

const titles: Record<string, string> = {
  '/': 'Dashboard',
  '/salons': 'Salonlar',
  '/barbers': 'Sartaroshlar',
  '/customers': 'Mijozlar',
  '/bookings': 'Bronlar',
  '/categories': 'Kategoriyalar',
  '/regions': 'Hududlar',
  '/banners': 'Bannerlar',
  '/notifications': 'Bildirishnomalar',
  '/reports': 'Hisobotlar',
  '/settings': 'Sozlamalar',
};

export default function Header({ collapsed }: { collapsed: boolean }) {
  const location = useLocation();
  const title = titles[location.pathname] || 'StilTime';

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 flex-shrink-0 sticky top-0 z-10 shadow-sm">
      <h1 className="text-lg font-semibold text-gray-900">{title}</h1>

      <div className="flex items-center gap-3">
        <div className="relative hidden md:block">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="search"
            placeholder="Qidirish..."
            className="bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 rounded-xl pl-9 pr-4 py-2 text-sm w-56 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
          />
        </div>

        <button className="relative w-9 h-9 bg-gray-50 border border-gray-200 rounded-xl flex items-center justify-center text-gray-500 hover:text-primary-600 hover:border-primary-300 transition-all">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-primary-500 rounded-full" />
        </button>
      </div>
    </header>
  );
}
