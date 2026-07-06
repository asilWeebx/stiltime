import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Search, Users, Star, Phone, Crown } from 'lucide-react';
import { usersAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';

export default function CustomersPage() {
  const [search, setSearch] = useState('');
  const { data, isLoading } = useQuery({
    queryKey: ['customers', search],
    queryFn: () => usersAPI.list({ role: 'customer', search }).then(r => r.data),
  });
  const customers = data?.results || data || [];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Mijoz qidirish..." className="bg-white border border-gray-200 text-gray-900 placeholder-slate-500 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 w-full" />
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2.5 rounded-xl">
          <Users className="w-4 h-4" />
          <span>{customers.length} ta mijoz</span>
        </div>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="table-wrapper">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="table-header px-6 py-4 text-left">Mijoz</th>
                <th className="table-header px-6 py-4 text-left">Telefon</th>
                <th className="table-header px-6 py-4 text-left">Jins</th>
                <th className="table-header px-6 py-4 text-left">Til</th>
                <th className="table-header px-6 py-4 text-left">Status</th>
                <th className="table-header px-6 py-4 text-left">Qo'shilgan</th>
              </tr>
            </thead>
            <tbody>
              {customers.map((c: any, i: number) => (
                <motion.tr key={c.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.03 }} className="table-row">
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white text-sm font-bold">
                        {(c.full_name || c.phone)?.[0] || 'M'}
                      </div>
                      <span className="font-medium">{c.full_name || '—'}</span>
                    </div>
                  </td>
                  <td className="table-cell text-gray-500"><div className="flex items-center gap-1.5"><Phone className="w-3.5 h-3.5" />{c.phone}</div></td>
                  <td className="table-cell">{c.gender === 'male' ? '👨 Erkak' : c.gender === 'female' ? '👩 Ayol' : '—'}</td>
                  <td className="table-cell">{c.language === 'uz' ? '🇺🇿 UZ' : c.language === 'ru' ? '🇷🇺 RU' : '🇺🇸 EN'}</td>
                  <td className="table-cell">{c.is_verified ? <span className="badge-green">Tasdiqlangan</span> : <span className="badge-yellow">Tasdiqlanmagan</span>}</td>
                  <td className="table-cell text-gray-500 text-sm">{c.date_joined?.split('T')[0]}</td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
