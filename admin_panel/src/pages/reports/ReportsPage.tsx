import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { dashboardAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import { Download } from 'lucide-react';

const PIE_COLORS = ['#3b82f6', '#f59e0b', '#10b981', '#3b82f6', '#ef4444'];

export default function ReportsPage() {
  const { data, isLoading } = useQuery({ queryKey: ['dashboard'], queryFn: () => dashboardAPI.getStats().then(r => r.data) });
  if (isLoading) return <LoadingSpinner />;
  const { last_7_days, top_salons } = data || {};
  const pieData = (top_salons || []).map((s: any) => ({ name: s.name, value: s.total_bookings }));
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div><h2 className="text-lg font-semibold text-gray-900">Hisobotlar</h2><p className="text-sm text-gray-500">So'nggi 7 kunlik statistika</p></div>
        <button className="btn-secondary"><Download className="w-4 h-4" /> Excel yuklab olish</button>
      </div>
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="card p-6">
          <h3 className="font-semibold text-gray-900 mb-4">Kunlik Bronlar</h3>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={last_7_days || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="date" tick={{ fill: '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 12 }} />
              <Bar dataKey="bookings" name="Bronlar" fill="#3b82f6" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="card p-6">
          <h3 className="font-semibold text-gray-900 mb-4">Top Salonlar</h3>
          <ResponsiveContainer width="100%" height={260}>
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" outerRadius={90} dataKey="value">
                {pieData.map((_: any, i: number) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
              </Pie>
              <Tooltip contentStyle={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 12 }} />
            </PieChart>
          </ResponsiveContainer>
        </motion.div>
      </div>
    </div>
  );
}
