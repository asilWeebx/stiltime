import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search, CheckCircle, XCircle,
  Star, Scissors, Phone, Building2, Lock,
  Edit2, X, Save, Trash2, AlertTriangle, Image as ImageIcon, Upload, Loader2, Check,
} from 'lucide-react';
import { barbersAPI, salonsAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import toast from 'react-hot-toast';
import clsx from 'clsx';

type StatusFilter = 'all' | 'pending' | 'approved' | 'rejected';

export default function BarbersPage() {
  const [status, setStatus] = useState<StatusFilter>('pending');
  const [search, setSearch] = useState('');
  const [editBarber, setEditBarber] = useState<any>(null);
  const [rejectBarber, setRejectBarber] = useState<any>(null);
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['barbers', status, search],
    queryFn: () => barbersAPI.list({ status: status === 'all' ? undefined : status, search }).then(r => r.data),
  });

  const verifyMutation = useMutation({
    mutationFn: ({ id, action, reason }: { id: number; action: 'approve' | 'reject'; reason?: string }) =>
      barbersAPI.verify(id, action, reason),
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: ['barbers'] });
      setRejectBarber(null);
      toast.success(vars.action === 'approve' ? 'Sartarosh tasdiqlandi' : 'Sartarosh rad etildi');
    },
    onError: () => toast.error('Xatolik yuz berdi'),
  });

  const statusTabs = [
    { key: 'pending', label: 'Kutayotganlar' },
    { key: 'approved', label: 'Tasdiqlanganlar' },
    { key: 'rejected', label: 'Rad etilganlar' },
    { key: 'all', label: 'Hammasi' },
  ];

  const statusBadge = (s: string) => ({
    pending:  <span className="badge-yellow">Kutilmoqda</span>,
    approved: <span className="badge-green">Tasdiqlangan</span>,
    rejected: <span className="badge-red">Rad etildi</span>,
  }[s] || <span className="badge-gray">{s}</span>);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Tabs + Search */}
      <div className="flex items-center gap-2 flex-wrap">
        {statusTabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => setStatus(tab.key as StatusFilter)}
            className={clsx(
              'px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200',
              status === tab.key
                ? 'bg-primary-600/20 text-primary-300 border border-primary-500/30'
                : 'bg-white text-gray-500 border border-gray-200 hover:border-gray-300'
            )}
          >
            {tab.label}
          </button>
        ))}
        <div className="ml-auto relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Qidirish..."
            className="bg-white border border-gray-200 text-gray-900 placeholder-slate-500 rounded-xl pl-9 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 w-56"
          />
        </div>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {(data?.results || data || []).map((barber: any, i: number) => (
            <motion.div
              key={barber.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="card p-5 hover:border-primary-500/30 transition-all duration-300"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary-500 to-purple-700 flex items-center justify-center text-white font-bold text-lg">
                    {barber.user?.full_name?.[0] || barber.full_name?.[0] || 'S'}
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">{barber.user?.full_name || barber.full_name}</p>
                    <p className="text-sm text-gray-500 flex items-center gap-1">
                      <Phone className="w-3 h-3" /> {barber.user?.phone || barber.phone}
                    </p>
                  </div>
                </div>
                {statusBadge(barber.status)}
              </div>

              <div className="space-y-2 mb-4">
                {barber.salon_name && (
                  <div className="flex items-center gap-2 text-sm text-gray-500">
                    <Building2 className="w-4 h-4 text-primary-400" />
                    <span>{barber.salon_name}</span>
                  </div>
                )}
                {barber.specialization && (
                  <div className="flex items-center gap-2 text-sm text-gray-500">
                    <Scissors className="w-4 h-4 text-primary-400" />
                    <span>{barber.specialization}</span>
                  </div>
                )}
                <div className="flex items-center gap-2 text-sm text-gray-500">
                  <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
                  <span>{barber.rating} ({barber.total_reviews} sharh)</span>
                </div>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setEditBarber(barber)}
                  className="flex-1 bg-primary-600/10 hover:bg-primary-600/20 text-primary-400 border border-primary-500/30 px-3 py-2 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-1.5"
                >
                  <Edit2 className="w-4 h-4" /> Boshqarish
                </button>
                {barber.status === 'pending' && (
                  <>
                    <button
                      onClick={() => verifyMutation.mutate({ id: barber.id, action: 'approve' })}
                      disabled={verifyMutation.isPending}
                      className="flex-1 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30 px-3 py-2 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-1.5"
                    >
                      <CheckCircle className="w-4 h-4" /> Tasdiqlash
                    </button>
                    <button
                      onClick={() => setRejectBarber(barber)}
                      disabled={verifyMutation.isPending}
                      className="flex-1 bg-red-600/20 hover:bg-red-600/30 text-red-400 border border-red-500/30 px-3 py-2 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-1.5"
                    >
                      <XCircle className="w-4 h-4" /> Rad etish
                    </button>
                  </>
                )}
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Edit / Manage Modal */}
      <AnimatePresence>
        {editBarber && (
          <EditBarberModal
            barber={editBarber}
            onClose={() => setEditBarber(null)}
            onSaved={(updated) => {
              qc.invalidateQueries({ queryKey: ['barbers'] });
              setEditBarber(updated);
            }}
            onDeleted={() => {
              qc.invalidateQueries({ queryKey: ['barbers'] });
              setEditBarber(null);
            }}
          />
        )}
      </AnimatePresence>

      {/* Reject Modal */}
      <AnimatePresence>
        {rejectBarber && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={() => setRejectBarber(null)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="card p-6 w-full max-w-md"
              onClick={e => e.stopPropagation()}
            >
              <h3 className="text-lg font-semibold text-gray-900 mb-4">
                Rad etish sababi: <span className="text-primary-400">{rejectBarber.user?.full_name}</span>
              </h3>
              <RejectForm
                onSubmit={(reason) => verifyMutation.mutate({ id: rejectBarber.id, action: 'reject', reason })}
                onCancel={() => setRejectBarber(null)}
                loading={verifyMutation.isPending}
              />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function EditBarberModal({ barber, onClose, onSaved, onDeleted }: {
  barber: any;
  onClose: () => void;
  onSaved: (updated: any) => void;
  onDeleted: () => void;
}) {
  const [tab, setTab] = useState<'info' | 'portfolio'>('info');
  const [salonId, setSalonId] = useState<string>(barber.salon_id?.toString() || '');
  const [newPassword, setNewPassword] = useState('');
  const [specialization, setSpecialization] = useState(barber.specialization || '');
  const [saving, setSaving] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const { data: salonsData } = useQuery({
    queryKey: ['salons-for-barber'],
    queryFn: () => salonsAPI.list({ page_size: 100 }).then(r => r.data),
  });
  const salons: any[] = salonsData?.results || salonsData || [];

  async function handleSave() {
    setSaving(true);
    try {
      const payload: Record<string, any> = { specialization };
      if (salonId) payload.salon_id = parseInt(salonId);
      else payload.salon_id = null;
      if (newPassword.trim()) payload.new_password = newPassword.trim();

      const res = await barbersAPI.update(barber.id, payload);
      toast.success("Sartarosh ma'lumotlari yangilandi");
      onSaved(res.data);
    } catch (e: any) {
      const msg = e?.response?.data?.error || 'Xatolik yuz berdi';
      toast.error(msg);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    setDeleting(true);
    try {
      await barbersAPI.delete(barber.id);
      toast.success("Sartarosh o'chirildi");
      onDeleted();
    } catch {
      toast.error('Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  const info = barber.user || barber;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        className="card p-0 w-full max-w-lg overflow-hidden relative"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-semibold text-gray-900">Sartarosh boshqaruvi</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-gray-100 px-6">
          {(['info', 'portfolio'] as const).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={clsx(
                'px-4 py-3 text-sm font-medium border-b-2 -mb-px transition-colors',
                tab === t ? 'border-primary-500 text-primary-600' : 'border-transparent text-gray-500 hover:text-gray-800'
              )}
            >
              {t === 'info' ? "Ma'lumotlar" : 'Portfolio'}
            </button>
          ))}
        </div>

        {tab === 'portfolio' && (
          <PortfolioTab barberId={barber.id} />
        )}

        {tab === 'info' && <>
        {/* Info block */}
        <div className="px-6 py-5 bg-gray-50 border-b border-gray-100">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary-500 to-purple-700 flex items-center justify-center text-white font-bold text-xl">
              {info.full_name?.[0] || 'S'}
            </div>
            <div>
              <p className="font-semibold text-gray-900 text-base">{info.full_name}</p>
              <p className="text-sm text-gray-500 mt-0.5">ID: #{barber.id}</p>
            </div>
            <div className="ml-auto">
              {{
                pending:  <span className="badge-yellow">Kutilmoqda</span>,
                approved: <span className="badge-green">Tasdiqlangan</span>,
                rejected: <span className="badge-red">Rad etildi</span>,
              }[barber.status as string] || <span className="badge-gray">{barber.status}</span>}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="flex items-center gap-2 bg-white rounded-xl px-3 py-2.5 border border-gray-100">
              <Phone className="w-4 h-4 text-primary-400 shrink-0" />
              <div>
                <p className="text-xs text-gray-400">Telefon</p>
                <p className="text-sm font-medium text-gray-900">{info.phone}</p>
              </div>
            </div>
            <div className="flex items-center gap-2 bg-white rounded-xl px-3 py-2.5 border border-gray-100">
              <Building2 className="w-4 h-4 text-primary-400 shrink-0" />
              <div>
                <p className="text-xs text-gray-400">Joriy salon</p>
                <p className="text-sm font-medium text-gray-900">{barber.salon_name || '—'}</p>
              </div>
            </div>
            <div className="flex items-center gap-2 bg-white rounded-xl px-3 py-2.5 border border-gray-100">
              <Star className="w-4 h-4 text-amber-400 shrink-0" />
              <div>
                <p className="text-xs text-gray-400">Reyting</p>
                <p className="text-sm font-medium text-gray-900">{barber.rating} ({barber.total_reviews} sharh)</p>
              </div>
            </div>
            <div className="flex items-center gap-2 bg-white rounded-xl px-3 py-2.5 border border-gray-100">
              <Scissors className="w-4 h-4 text-primary-400 shrink-0" />
              <div>
                <p className="text-xs text-gray-400">Jami buyurtma</p>
                <p className="text-sm font-medium text-gray-900">{barber.total_bookings}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Edit fields */}
        <div className="px-6 py-5 space-y-4">
          {/* Specialization */}
          <div>
            <label className="text-sm font-medium text-gray-700 flex items-center gap-1.5 mb-1.5">
              <Scissors className="w-3.5 h-3.5 text-primary-400" /> Mutaxassislik
            </label>
            <input
              value={specialization}
              onChange={e => setSpecialization(e.target.value)}
              placeholder="Soch kesish, soqol olish..."
              className="input"
            />
          </div>

          {/* Salon change */}
          <div>
            <label className="text-sm font-medium text-gray-700 flex items-center gap-1.5 mb-1.5">
              <Building2 className="w-3.5 h-3.5 text-primary-400" /> Salonni o'zgartirish
            </label>
            <select
              value={salonId}
              onChange={e => setSalonId(e.target.value)}
              className="input"
            >
              <option value="">— Salon tanlanmagan —</option>
              {salons.map((s: any) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          </div>

          {/* Password change */}
          <div>
            <label className="text-sm font-medium text-gray-700 flex items-center gap-1.5 mb-1.5">
              <Lock className="w-3.5 h-3.5 text-primary-400" /> Yangi parol (o'zgartirish uchun)
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={e => setNewPassword(e.target.value)}
              placeholder="Kamida 6 ta belgi..."
              className="input"
            />
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 pb-5 space-y-3">
          <div className="flex gap-3">
            <button onClick={onClose} className="btn-secondary flex-1 justify-center">
              Bekor qilish
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="flex-1 btn-primary justify-center flex items-center gap-2"
            >
              <Save className="w-4 h-4" />
              {saving ? 'Saqlanmoqda...' : 'Saqlash'}
            </button>
          </div>
          <button
            onClick={() => setConfirmDelete(true)}
            className="w-full bg-red-600/10 hover:bg-red-600/20 text-red-500 border border-red-500/30 px-4 py-2.5 rounded-xl font-medium transition-all flex items-center justify-center gap-2 text-sm"
          >
            <Trash2 className="w-4 h-4" /> Profilni o'chirish
          </button>
        </div>

        </>}

        {/* Delete confirm */}
        <AnimatePresence>
          {confirmDelete && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center rounded-2xl p-6"
            >
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
                className="bg-white rounded-2xl p-6 w-full max-w-sm text-center shadow-2xl"
              >
                <div className="w-14 h-14 bg-red-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <AlertTriangle className="w-7 h-7 text-red-500" />
                </div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">Profilni o'chirish</h4>
                <p className="text-sm text-gray-500 mb-6">
                  <span className="font-medium text-gray-800">{barber.user?.full_name || barber.full_name}</span> profili va uning hisobi butunlay o'chiriladi. Bu amalni qaytarib bo'lmaydi.
                </p>
                <div className="flex gap-3">
                  <button
                    onClick={() => setConfirmDelete(false)}
                    className="flex-1 btn-secondary justify-center"
                  >
                    Bekor
                  </button>
                  <button
                    onClick={handleDelete}
                    disabled={deleting}
                    className="flex-1 bg-red-600 hover:bg-red-700 text-white px-4 py-2.5 rounded-xl font-medium transition-all flex items-center justify-center gap-2"
                  >
                    <Trash2 className="w-4 h-4" />
                    {deleting ? "O'chirilmoqda..." : "O'chirish"}
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}

function PortfolioTab({ barberId }: { barberId: number }) {
  const qc = useQueryClient();
  const afterRef = useRef<HTMLInputElement>(null);
  const beforeRef = useRef<HTMLInputElement>(null);
  const [afterFile, setAfterFile] = useState<File | null>(null);
  const [afterPreview, setAfterPreview] = useState<string | null>(null);
  const [beforeFile, setBeforeFile] = useState<File | null>(null);
  const [beforePreview, setBeforePreview] = useState<string | null>(null);
  const [caption, setCaption] = useState('');
  const [uploading, setUploading] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const { data: items = [], refetch } = useQuery({
    queryKey: ['barber-portfolio', barberId],
    queryFn: () => barbersAPI.portfolioList(barberId).then(r => r.data as any[]),
  });

  const handleAfter = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]; if (!f) return;
    setAfterFile(f); setAfterPreview(URL.createObjectURL(f)); e.target.value = '';
  };
  const handleBefore = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]; if (!f) return;
    setBeforeFile(f); setBeforePreview(URL.createObjectURL(f)); e.target.value = '';
  };

  const handleUpload = async () => {
    if (!afterFile) { toast.error('"Keyin" rasmi kerak'); return; }
    setUploading(true);
    try {
      await barbersAPI.portfolioAdd(barberId, afterFile, beforeFile, caption);
      toast.success("Portfolio qo'shildi");
      setAfterFile(null); setAfterPreview(null);
      setBeforeFile(null); setBeforePreview(null);
      setCaption('');
      refetch(); qc.invalidateQueries({ queryKey: ['barbers'] });
    } catch { toast.error('Xatolik yuz berdi'); }
    finally { setUploading(false); }
  };

  const handleDelete = async (itemId: number) => {
    setDeletingId(itemId);
    try {
      await barbersAPI.portfolioDelete(barberId, itemId);
      toast.success("O'chirildi");
      refetch();
    } catch { toast.error('Xatolik yuz berdi'); }
    finally { setDeletingId(null); }
  };

  return (
    <div className="px-6 py-5 space-y-5 max-h-[60vh] overflow-y-auto">
      {/* Upload form */}
      <div className="border border-gray-200 rounded-2xl p-4 space-y-3 bg-gray-50">
        <p className="text-sm font-semibold text-gray-700 flex items-center gap-1.5"><ImageIcon className="w-4 h-4 text-primary-500" /> Yangi portfolio qo'shish</p>
        <div className="grid grid-cols-2 gap-3">
          {/* After (required) */}
          <div>
            <label className="text-xs font-medium text-gray-600 mb-1.5 block">Keyin * <span className="text-gray-400 font-normal">(majburiy)</span></label>
            <div onClick={() => afterRef.current?.click()} className="cursor-pointer border-2 border-dashed border-gray-300 rounded-xl overflow-hidden hover:border-primary-400 transition-colors flex items-center justify-center bg-white" style={{ height: 100 }}>
              {afterPreview
                ? <img src={afterPreview} className="w-full h-full object-cover" alt="" />
                : <div className="flex flex-col items-center gap-1 text-gray-400"><Upload className="w-5 h-5" /><span className="text-xs">Yuklash</span></div>
              }
            </div>
            <input ref={afterRef} type="file" accept="image/*" className="hidden" onChange={handleAfter} />
          </div>
          {/* Before (optional) */}
          <div>
            <label className="text-xs font-medium text-gray-600 mb-1.5 block">Oldin <span className="text-gray-400 font-normal">(ixtiyoriy)</span></label>
            <div onClick={() => beforeRef.current?.click()} className="cursor-pointer border-2 border-dashed border-gray-300 rounded-xl overflow-hidden hover:border-primary-400 transition-colors flex items-center justify-center bg-white" style={{ height: 100 }}>
              {beforePreview
                ? <img src={beforePreview} className="w-full h-full object-cover" alt="" />
                : <div className="flex flex-col items-center gap-1 text-gray-400"><Upload className="w-5 h-5" /><span className="text-xs">Yuklash</span></div>
              }
            </div>
            <input ref={beforeRef} type="file" accept="image/*" className="hidden" onChange={handleBefore} />
          </div>
        </div>
        <input value={caption} onChange={e => setCaption(e.target.value)} placeholder="Izoh (ixtiyoriy)..." className="input text-sm" />
        <button onClick={handleUpload} disabled={uploading || !afterFile} className="btn-primary w-full justify-center flex items-center gap-2 py-2.5 text-sm disabled:opacity-50">
          {uploading ? <><Loader2 className="w-4 h-4 animate-spin" /> Yuklanmoqda...</> : <><Upload className="w-4 h-4" /> Qo'shish</>}
        </button>
      </div>

      {/* Existing items */}
      {items.length === 0
        ? <p className="text-center text-gray-400 text-sm py-4">Portfolio bo'sh</p>
        : <div className="grid grid-cols-2 gap-3">
            {items.map((item: any) => (
              <PortfolioItem
                key={item.id}
                item={item}
                barberId={barberId}
                deletingId={deletingId}
                onDelete={handleDelete}
                onRefresh={refetch}
              />
            ))}
          </div>
      }
    </div>
  );
}

function PortfolioItem({ item, barberId, deletingId, onDelete, onRefresh }: {
  item: any; barberId: number; deletingId: number | null;
  onDelete: (id: number) => void; onRefresh: () => void;
}) {
  const [actioning, setActioning] = useState(false);
  const [showRejectInput, setShowRejectInput] = useState(false);
  const [rejectReason, setRejectReason] = useState('');

  const statusBadge = {
    pending:  <span className="text-[9px] font-bold bg-amber-400 text-white px-1.5 py-0.5 rounded">KUTILMOQDA</span>,
    approved: <span className="text-[9px] font-bold bg-emerald-500 text-white px-1.5 py-0.5 rounded">TASDIQLANDI</span>,
    rejected: <span className="text-[9px] font-bold bg-red-500 text-white px-1.5 py-0.5 rounded">RAD ETILDI</span>,
  }[item.status as string] ?? null;

  const handleApprove = async () => {
    setActioning(true);
    try {
      await barbersAPI.portfolioApprove(barberId, item.id);
      toast.success('Tasdiqlandi');
      onRefresh();
    } catch { toast.error('Xatolik'); }
    finally { setActioning(false); }
  };

  const handleReject = async () => {
    setActioning(true);
    try {
      await barbersAPI.portfolioReject(barberId, item.id, rejectReason);
      toast.success("Rad etildi");
      setShowRejectInput(false);
      onRefresh();
    } catch { toast.error('Xatolik'); }
    finally { setActioning(false); }
  };

  return (
    <div className={`rounded-xl overflow-hidden border ${item.status === 'rejected' ? 'border-red-300' : item.status === 'approved' ? 'border-emerald-300' : 'border-amber-300'}`}>
      <div className="flex relative">
        {item.before_image && (
          <div className="flex-1 relative">
            <img src={item.before_image} className="w-full h-24 object-cover" alt="" />
            <span className="absolute top-1 left-1 text-white text-[9px] font-bold bg-black/50 px-1.5 py-0.5 rounded">OLDIN</span>
          </div>
        )}
        <div className="flex-1 relative">
          <img src={item.after_image} className="w-full h-24 object-cover" alt="" />
          <span className="absolute top-1 left-1 text-white text-[9px] font-bold bg-emerald-500/80 px-1.5 py-0.5 rounded">KEYIN</span>
        </div>
        <button
          onClick={() => onDelete(item.id)}
          disabled={deletingId === item.id}
          className="absolute top-1 right-1 w-6 h-6 bg-red-500 rounded-full flex items-center justify-center text-white shadow disabled:opacity-60"
        >
          {deletingId === item.id ? <Loader2 className="w-3 h-3 animate-spin" /> : <X className="w-3 h-3" />}
        </button>
      </div>
      <div className="px-2 py-1.5 space-y-1.5 bg-white">
        <div className="flex items-center justify-between">
          {statusBadge}
          {item.caption && <p className="text-[10px] text-gray-400 truncate ml-1">{item.caption}</p>}
        </div>
        {item.status === 'rejected' && item.rejection_reason && (
          <p className="text-[10px] text-red-500">Sabab: {item.rejection_reason}</p>
        )}
        {item.status === 'pending' && !showRejectInput && (
          <div className="flex gap-1.5">
            <button onClick={handleApprove} disabled={actioning} className="flex-1 bg-emerald-500 hover:bg-emerald-600 text-white text-[10px] font-bold py-1 rounded-lg disabled:opacity-50 flex items-center justify-center gap-1">
              {actioning ? <Loader2 className="w-3 h-3 animate-spin" /> : <Check className="w-3 h-3" />} Tasdiqlash
            </button>
            <button onClick={() => setShowRejectInput(true)} disabled={actioning} className="flex-1 bg-red-500 hover:bg-red-600 text-white text-[10px] font-bold py-1 rounded-lg disabled:opacity-50 flex items-center justify-center gap-1">
              <X className="w-3 h-3" /> Rad etish
            </button>
          </div>
        )}
        {showRejectInput && (
          <div className="space-y-1">
            <input value={rejectReason} onChange={e => setRejectReason(e.target.value)} placeholder="Sabab..." className="input text-xs py-1" />
            <div className="flex gap-1">
              <button onClick={handleReject} disabled={actioning} className="flex-1 bg-red-500 text-white text-[10px] font-bold py-1 rounded-lg flex items-center justify-center gap-1">
                {actioning ? <Loader2 className="w-3 h-3 animate-spin" /> : null} Yuborish
              </button>
              <button onClick={() => setShowRejectInput(false)} className="flex-1 bg-gray-100 text-gray-600 text-[10px] font-bold py-1 rounded-lg">Bekor</button>
            </div>
          </div>
        )}
        {item.status === 'approved' && (
          <button onClick={() => barbersAPI.portfolioReject(barberId, item.id, '').then(() => { toast.success("O'chirildi"); onRefresh(); })} className="w-full text-[10px] text-gray-400 hover:text-red-500 py-0.5">Bekor qilish</button>
        )}
      </div>
    </div>
  );
}

function RejectForm({ onSubmit, onCancel, loading }: { onSubmit: (reason: string) => void; onCancel: () => void; loading: boolean }) {
  const [reason, setReason] = useState('');
  return (
    <div className="space-y-4">
      <textarea
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        placeholder="Rad etish sababini kiriting..."
        className="input resize-none"
        rows={4}
        autoFocus
      />
      <div className="flex gap-3">
        <button onClick={onCancel} className="btn-secondary flex-1 justify-center">Bekor</button>
        <button
          onClick={() => onSubmit(reason)}
          disabled={loading}
          className="flex-1 bg-red-600/20 hover:bg-red-600/30 text-red-400 border border-red-500/30 px-4 py-2.5 rounded-xl font-medium transition-all flex items-center justify-center gap-2"
        >
          <XCircle className="w-4 h-4" /> Rad etish
        </button>
      </div>
    </div>
  );
}
