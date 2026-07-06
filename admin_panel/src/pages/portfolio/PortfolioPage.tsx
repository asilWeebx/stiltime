import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Check, X, Loader2, ImageIcon, Clock, User } from 'lucide-react';
import { barbersAPI } from '../../api';
import toast from 'react-hot-toast';

export default function PortfolioPage() {
  const qc = useQueryClient();
  const [filter, setFilter] = useState<'pending' | 'all'>('pending');

  const { data: pendingItems = [], isLoading, refetch } = useQuery({
    queryKey: ['portfolio-pending'],
    queryFn: () => barbersAPI.pendingPortfolio().then(r => {
      const data = r.data;
      return Array.isArray(data) ? data : (data?.results ?? data?.data ?? []);
    }),
  });

  const filtered = filter === 'pending'
    ? pendingItems.filter((i: any) => i.status === 'pending')
    : pendingItems;

  const pendingCount = pendingItems.filter((i: any) => i.status === 'pending').length;

  return (
    <div className="p-6 max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Portfolio moderatsiyasi</h1>
          <p className="text-sm text-gray-500 mt-0.5">Sartaroshlar yuborgan portfolio rasmlarini ko'rib chiqing</p>
        </div>
        {pendingCount > 0 && (
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-amber-50 text-amber-700 border border-amber-200 rounded-full text-sm font-semibold">
            <Clock className="w-4 h-4" />
            {pendingCount} ta kutilmoqda
          </span>
        )}
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2">
        {(['pending', 'all'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
              filter === f
                ? 'bg-primary-600 text-white shadow-sm'
                : 'bg-white text-gray-500 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {f === 'pending' ? `Kutilmoqda (${pendingCount})` : `Barchasi (${pendingItems.length})`}
          </button>
        ))}
        <button
          onClick={() => { qc.invalidateQueries({ queryKey: ['portfolio-pending'] }); }}
          className="ml-auto px-4 py-2 rounded-xl text-sm font-medium bg-white border border-gray-200 text-gray-600 hover:bg-gray-50"
        >
          Yangilash
        </button>
      </div>

      {/* Content */}
      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 animate-spin text-primary-500" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center mb-4">
            <ImageIcon className="w-8 h-8 text-gray-400" />
          </div>
          <p className="text-gray-600 font-semibold text-lg">
            {filter === 'pending' ? 'Kutilayotgan so\'rovlar yo\'q' : 'Portfolio bo\'sh'}
          </p>
          <p className="text-gray-400 text-sm mt-1">Sartaroshlar yuborgan rasmlar bu yerda ko\'rinadi</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filtered.map((item: any) => (
            <PortfolioCard key={item.id} item={item} onRefresh={refetch} />
          ))}
        </div>
      )}
    </div>
  );
}

function PortfolioCard({ item, onRefresh }: { item: any; onRefresh: () => void }) {
  const [actioning, setActioning] = useState(false);
  const [showReject, setShowReject] = useState(false);
  const [reason, setReason] = useState('');

  const statusStyle = {
    pending:  { bg: 'bg-amber-50 border-amber-200',  badge: 'bg-amber-400 text-white',  label: 'Kutilmoqda' },
    approved: { bg: 'bg-emerald-50 border-emerald-200', badge: 'bg-emerald-500 text-white', label: 'Tasdiqlandi' },
    rejected: { bg: 'bg-red-50 border-red-200',     badge: 'bg-red-500 text-white',    label: 'Rad etildi' },
  }[item.status as string] ?? { bg: 'bg-gray-50 border-gray-200', badge: 'bg-gray-400 text-white', label: item.status };

  const handleApprove = async () => {
    setActioning(true);
    try {
      await barbersAPI.portfolioApprove(item.barber_id ?? item.barber, item.id);
      toast.success('Portfolio tasdiqlandi');
      onRefresh();
    } catch {
      toast.error('Xatolik yuz berdi');
    } finally {
      setActioning(false);
    }
  };

  const handleReject = async () => {
    setActioning(true);
    try {
      await barbersAPI.portfolioReject(item.barber_id ?? item.barber, item.id, reason);
      toast.success('Rad etildi');
      setShowReject(false);
      setReason('');
      onRefresh();
    } catch {
      toast.error('Xatolik yuz berdi');
    } finally {
      setActioning(false);
    }
  };

  return (
    <div className={`rounded-2xl overflow-hidden border ${statusStyle.bg} flex flex-col`}>
      {/* Images */}
      <div className="relative flex">
        {item.before_image && (
          <div className="flex-1 relative">
            <img src={item.before_image} className="w-full object-cover" style={{ height: 140 }} alt="oldin" />
            <span className="absolute top-2 left-2 text-white text-[10px] font-bold bg-black/50 px-2 py-0.5 rounded-full">OLDIN</span>
          </div>
        )}
        <div className={item.before_image ? 'flex-1 relative' : 'w-full relative'}>
          <img src={item.after_image} className="w-full object-cover" style={{ height: 140 }} alt="keyin" />
          <span className="absolute top-2 left-2 text-white text-[10px] font-bold bg-emerald-500/90 px-2 py-0.5 rounded-full">KEYIN</span>
        </div>
        {/* Status badge */}
        <span className={`absolute top-2 right-2 text-[10px] font-bold px-2 py-0.5 rounded-full ${statusStyle.badge}`}>
          {statusStyle.label}
        </span>
      </div>

      {/* Info */}
      <div className="p-3 space-y-2 flex-1">
        {/* Barber name */}
        {item.barber_name && (
          <div className="flex items-center gap-1.5">
            <User className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
            <span className="text-xs text-gray-600 font-medium truncate">{item.barber_name}</span>
          </div>
        )}
        {item.caption && (
          <p className="text-xs text-gray-500 line-clamp-2">{item.caption}</p>
        )}
        {item.status === 'rejected' && item.rejection_reason && (
          <p className="text-xs text-red-600 bg-red-50 rounded-lg px-2 py-1">
            <span className="font-semibold">Sabab:</span> {item.rejection_reason}
          </p>
        )}

        {/* Actions for pending */}
        {item.status === 'pending' && !showReject && (
          <div className="flex gap-2 pt-1">
            <button
              onClick={handleApprove}
              disabled={actioning}
              className="flex-1 flex items-center justify-center gap-1 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-white text-xs font-bold py-2 rounded-xl transition-colors"
            >
              {actioning ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Check className="w-3.5 h-3.5" />}
              Tasdiqlash
            </button>
            <button
              onClick={() => setShowReject(true)}
              disabled={actioning}
              className="flex-1 flex items-center justify-center gap-1 bg-red-500 hover:bg-red-600 disabled:opacity-50 text-white text-xs font-bold py-2 rounded-xl transition-colors"
            >
              <X className="w-3.5 h-3.5" />
              Rad etish
            </button>
          </div>
        )}

        {showReject && (
          <div className="space-y-2 pt-1">
            <input
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="Rad etish sababi..."
              className="w-full border border-gray-200 rounded-xl px-3 py-1.5 text-xs focus:outline-none focus:border-primary-400"
            />
            <div className="flex gap-2">
              <button
                onClick={handleReject}
                disabled={actioning}
                className="flex-1 bg-red-500 hover:bg-red-600 disabled:opacity-50 text-white text-xs font-bold py-1.5 rounded-xl flex items-center justify-center gap-1"
              >
                {actioning ? <Loader2 className="w-3 h-3 animate-spin" /> : null}
                Yuborish
              </button>
              <button
                onClick={() => { setShowReject(false); setReason(''); }}
                className="px-3 py-1.5 text-gray-500 hover:text-gray-700 text-xs rounded-xl border border-gray-200 hover:bg-gray-50"
              >
                Bekor
              </button>
            </div>
          </div>
        )}

        {/* Approved: revoke option */}
        {item.status === 'approved' && (
          <button
            onClick={handleReject}
            disabled={actioning}
            className="w-full text-xs text-gray-400 hover:text-red-500 py-1 transition-colors"
          >
            Bekor qilish
          </button>
        )}
      </div>
    </div>
  );
}
