import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import {
  Store, Scissors, Users, CalendarCheck,
  TrendingUp, Clock, AlertCircle, DollarSign,
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, BarChart, Bar,
} from 'recharts';
import { dashboardAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { format } from 'date-fns';

const cardVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: (i: number) => ({ opacity: 1, y: 0, transition: { delay: i * 0.08, duration: 0.4 } }),
};

function StatCard({ icon: Icon, label, value, change, color, index }: any) {
  return (
    <motion.div custom={index} variants={cardVariants} initial="hidden" animate="visible" className="stat-card">
      <div className="flex items-center justify-between">
        <div className={`w-12 h-12 rounded-2xl ${color} flex items-center justify-center`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        {change !== undefined && (
          <span className={`badge ${change >= 0 ? 'badge-green' : 'badge-red'}`}>
            {change >= 0 ? '+' : ''}{change}%
          </span>
        )}
      </div>
      <div>
        <p className="text-3xl font-display font-bold text-gray-900">{value?.toLocaleString()}</p>
        <p className="text-sm text-gray-500 mt-1">{label}</p>
      </div>
    </motion.div>
  );
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-gray-100 border border-gray-200 rounded-xl p-3 text-sm">
        <p className="text-gray-500 mb-2">{label}</p>
        {payload.map((p: any) => (
          <p key={p.name} style={{ color: p.color }} className="font-medium">
            {p.name === 'revenue' ? `${(p.value).toLocaleString()} so'm` : `${p.value} bron`}
          </p>
        ))}
      </div>
    );
  }
  return null;
};

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => dashboardAPI.getStats().then(r => r.data),
    refetchInterval: 60_000,
  });

  if (isLoading) return <LoadingSpinner />;

  const { stats, last_7_days, top_salons, recent_bookings } = data || {};

  const statCards = [
    { icon: Store, label: 'Jami salonlar', value: stats?.total_salons, color: 'bg-gradient-to-br from-purple-500 to-primary-700', change: 12 },
    { icon: Scissors, label: 'Sartaroshlar', value: stats?.total_barbers, color: 'bg-gradient-to-br from-blue-500 to-cyan-600', change: 8 },
    { icon: Users, label: 'Mijozlar', value: stats?.total_customers, color: 'bg-gradient-to-br from-emerald-500 to-teal-600', change: 23 },
    { icon: CalendarCheck, label: 'Jami bronlar', value: stats?.total_bookings, color: 'bg-gradient-to-br from-amber-500 to-orange-600', change: 18 },
    { icon: Clock, label: 'Bugungi bronlar', value: stats?.today_bookings, color: 'bg-gradient-to-br from-pink-500 to-rose-600' },
    { icon: AlertCircle, label: 'Kutayotgan sartaroshlar', value: stats?.pending_barbers, color: 'bg-gradient-to-br from-yellow-500 to-amber-600' },
    { icon: DollarSign, label: 'Oylik daromad', value: `${(stats?.monthly_revenue || 0).toLocaleString()} so'm`, color: 'bg-gradient-to-br from-violet-500 to-purple-700' },
  ];

  const statusColors: Record<string, string> = {
    pending: 'badge-yellow',
    confirmed: 'badge-blue',
    in_progress: 'badge-purple',
    completed: 'badge-green',
    cancelled: 'badge-red',
    no_show: 'badge-gray',
  };
  const statusLabels: Record<string, string> = {
    pending: 'Kutilmoqda',
    confirmed: 'Tasdiqlangan',
    in_progress: 'Davom etmoqda',
    completed: 'Bajarildi',
    cancelled: 'Bekor',
    no_show: 'Kelmadi',
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-7 gap-4">
        {statCards.map((card, i) => (
          <StatCard key={card.label} {...card} index={i} />
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="xl:col-span-2 card p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-semibold text-gray-900">Bronlar va Daromad</h3>
              <p className="text-sm text-gray-500">So'nggi 7 kun</p>
            </div>
            <div className="flex items-center gap-4 text-xs">
              <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded-full bg-primary-500" />Bronlar</span>
              <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded-full bg-amber-500" />Daromad</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={last_7_days || []}>
              <defs>
                <linearGradient id="colorBookings" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="date" tick={{ fill: '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="bookings" name="bookings" stroke="#3b82f6" fill="url(#colorBookings)" strokeWidth={2} dot={{ fill: '#3b82f6', r: 3 }} />
              <Area type="monotone" dataKey="revenue" name="revenue" stroke="#f59e0b" fill="url(#colorRevenue)" strokeWidth={2} dot={{ fill: '#f59e0b', r: 3 }} />
            </AreaChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Top Salons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
          className="card p-6"
        >
          <h3 className="font-semibold text-gray-900 mb-4">Top Salonlar</h3>
          <div className="space-y-3">
            {(top_salons || []).map((salon: any, i: number) => (
              <div key={salon.id} className="flex items-center gap-3">
                <span className="w-7 h-7 rounded-lg bg-gray-100 flex items-center justify-center text-xs font-bold text-primary-400">
                  {i + 1}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-800 truncate">{salon.name}</p>
                  <p className="text-xs text-gray-400">{salon.total_bookings} bron</p>
                </div>
                <span className="text-sm font-medium text-amber-400">⭐ {salon.rating}</span>
              </div>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Recent Bookings */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="table-wrapper"
      >
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="font-semibold text-gray-900">So'nggi Bronlar</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="table-header px-6 py-3 text-left">ID</th>
                <th className="table-header px-6 py-3 text-left">Mijoz</th>
                <th className="table-header px-6 py-3 text-left">Sartarosh</th>
                <th className="table-header px-6 py-3 text-left">Salon</th>
                <th className="table-header px-6 py-3 text-left">Sana</th>
                <th className="table-header px-6 py-3 text-left">Summa</th>
                <th className="table-header px-6 py-3 text-left">Status</th>
              </tr>
            </thead>
            <tbody>
              {(recent_bookings || []).map((b: any) => (
                <tr key={b.id} className="table-row">
                  <td className="table-cell font-mono text-primary-400">#{b.id}</td>
                  <td className="table-cell">{b.customer || 'Walk-in'}</td>
                  <td className="table-cell">{b.barber_name}</td>
                  <td className="table-cell">{b.salon_name}</td>
                  <td className="table-cell text-gray-500">{b.date} {b.start_time}</td>
                  <td className="table-cell font-medium text-emerald-400">{Number(b.final_price).toLocaleString()} so'm</td>
                  <td className="table-cell">
                    <span className={statusColors[b.status] || 'badge-gray'}>
                      {statusLabels[b.status] || b.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </motion.div>
    </div>
  );
}
