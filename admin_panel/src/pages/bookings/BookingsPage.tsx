import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Search, Filter, CalendarCheck } from 'lucide-react';
import { bookingsAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import clsx from 'clsx';

const STATUS_OPTIONS = [
  { value: '', label: 'Barchasi' },
  { value: 'pending', label: 'Kutilmoqda' },
  { value: 'confirmed', label: 'Tasdiqlangan' },
  { value: 'in_progress', label: 'Davom etmoqda' },
  { value: 'completed', label: 'Bajarildi' },
  { value: 'cancelled', label: 'Bekor' },
];

const STATUS_BADGE: Record<string, string> = {
  pending: 'badge-yellow', confirmed: 'badge-blue', in_progress: 'badge-purple',
  completed: 'badge-green', cancelled: 'badge-red', no_show: 'badge-gray',
};
const STATUS_LABEL: Record<string, string> = {
  pending: 'Kutilmoqda', confirmed: 'Tasdiqlangan', in_progress: 'Davom etmoqda',
  completed: 'Bajarildi', cancelled: 'Bekor qilindi', no_show: 'Kelmadi',
};

export default function BookingsPage() {
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const { data, isLoading } = useQuery({
    queryKey: ['bookings', status, search],
    queryFn: () => bookingsAPI.list({ status: status || undefined, search }).then(r => r.data),
  });
  const bookings = data?.results || data || [];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Qidirish..." className="bg-white border border-gray-200 text-gray-900 placeholder-slate-500 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 w-56" />
        </div>
        <div className="flex gap-2 flex-wrap">
          {STATUS_OPTIONS.map(opt => (
            <button key={opt.value} onClick={() => setStatus(opt.value)} className={clsx('px-3 py-2 rounded-xl text-xs font-medium transition-all', status === opt.value ? 'bg-primary-600/20 text-primary-300 border border-primary-500/30' : 'bg-white text-gray-500 border border-gray-200 hover:border-gray-200')}>
              {opt.label}
            </button>
          ))}
        </div>
        <div className="ml-auto flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-3 py-2.5 rounded-xl">
          <CalendarCheck className="w-4 h-4" /> {bookings.length} ta
        </div>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="table-wrapper">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="table-header px-6 py-4 text-left">ID</th>
                <th className="table-header px-6 py-4 text-left">Sartarosh</th>
                <th className="table-header px-6 py-4 text-left">Salon</th>
                <th className="table-header px-6 py-4 text-left">Sana & Vaqt</th>
                <th className="table-header px-6 py-4 text-left">Summa</th>
                <th className="table-header px-6 py-4 text-left">Manba</th>
                <th className="table-header px-6 py-4 text-left">Status</th>
              </tr>
            </thead>
            <tbody>
              {bookings.map((b: any, i: number) => (
                <motion.tr key={b.id} initial={{ opacity: 0, y: 4 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03 }} className="table-row">
                  <td className="table-cell font-mono text-primary-400">#{b.id}</td>
                  <td className="table-cell font-medium">{b.barber_name}</td>
                  <td className="table-cell text-gray-500">{b.salon_name}</td>
                  <td className="table-cell"><div className="text-gray-800">{b.date}</div><div className="text-xs text-gray-400">{b.start_time} — {b.end_time}</div></td>
                  <td className="table-cell font-semibold text-emerald-400">{Number(b.final_price).toLocaleString()} so'm</td>
                  <td className="table-cell"><span className={clsx('badge', b.source === 'telegram' ? 'badge-blue' : b.source === 'walk_in' ? 'badge-gray' : 'badge-purple')}>{b.source === 'app' ? '📱 Ilova' : b.source === 'telegram' ? '✈️ Telegram' : '🚶 Walk-in'}</span></td>
                  <td className="table-cell"><span className={STATUS_BADGE[b.status] || 'badge-gray'}>{STATUS_LABEL[b.status] || b.status}</span></td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
