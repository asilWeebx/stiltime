import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Plus, Search, Store, Star, MapPin, Users, Edit, Trash2, CheckCircle } from 'lucide-react';
import { salonsAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import toast from 'react-hot-toast';

export default function SalonsPage() {
  const [search, setSearch] = useState('');
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['salons', search],
    queryFn: () => salonsAPI.list({ search }).then(r => r.data),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => salonsAPI.delete(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['salons'] }); toast.success('Salon o\'chirildi'); },
  });

  const salons = data?.results || data || [];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Salon qidirish..."
            className="bg-white border border-gray-200 text-gray-900 placeholder-slate-500 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 w-64"
          />
        </div>
        <Link to="/salons/new" className="btn-primary">
          <Plus className="w-4 h-4" /> Salon qo'shish
        </Link>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="table-wrapper">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="table-header px-6 py-4 text-left">Salon</th>
                <th className="table-header px-6 py-4 text-left">Manzil</th>
                <th className="table-header px-6 py-4 text-left">Reyting</th>
                <th className="table-header px-6 py-4 text-left">Bronlar</th>
                <th className="table-header px-6 py-4 text-left">Status</th>
                <th className="table-header px-6 py-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {salons.map((salon: any, i: number) => (
                <motion.tr
                  key={salon.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.04 }}
                  className="table-row"
                >
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-purple-700 flex items-center justify-center text-white font-bold">
                        {salon.name[0]}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{salon.name}</p>
                        <p className="text-xs text-gray-400 capitalize">{salon.type?.replace('_', ' ')}</p>
                      </div>
                    </div>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center gap-1.5 text-gray-500">
                      <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
                      <span className="text-sm truncate max-w-[200px]">{salon.address || salon.region_name}</span>
                    </div>
                  </td>
                  <td className="table-cell">
                    <span className="flex items-center gap-1 text-amber-400 font-medium">
                      ⭐ {salon.rating || '—'}
                    </span>
                  </td>
                  <td className="table-cell">{salon.total_bookings || 0}</td>
                  <td className="table-cell">
                    <div className="flex gap-1.5">
                      {salon.is_active !== false ? <span className="badge-green">Faol</span> : <span className="badge-yellow">Nofaol</span>}
                      {salon.is_featured && <span className="badge-purple">Featured</span>}
                    </div>
                  </td>
                  <td className="table-cell text-right">
                    <div className="flex items-center justify-end gap-2">
                      <Link to={`/salons/${salon.id}/edit`} className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 hover:text-primary-400 transition-colors">
                        <Edit className="w-4 h-4" />
                      </Link>
                      <button
                        onClick={() => { if (confirm('O\'chirishni tasdiqlaysizmi?')) deleteMutation.mutate(salon.id); }}
                        className="p-2 rounded-lg hover:bg-red-500/10 text-gray-500 hover:text-red-400 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
