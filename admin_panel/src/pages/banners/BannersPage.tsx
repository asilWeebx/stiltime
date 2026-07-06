import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2, Image, X, Loader2 } from 'lucide-react';
import { bannersAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import toast from 'react-hot-toast';

export default function BannersPage() {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title: '', description: '', link: '', image: null as File | null });
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({ queryKey: ['banners'], queryFn: () => bannersAPI.list().then(r => r.data?.results ?? r.data) });

  const createMutation = useMutation({
    mutationFn: () => { const fd = new FormData(); fd.append('title', form.title); fd.append('description', form.description); if (form.link) fd.append('link', form.link); if (form.image) fd.append('image', form.image); return bannersAPI.create(fd); },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); setShowForm(false); toast.success('Banner yaratildi'); },
    onError: () => toast.error('Xatolik'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => bannersAPI.delete(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); toast.success("Banner o'chirildi"); },
  });

  const banners = data?.results || data || [];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-end">
        <button onClick={() => setShowForm(true)} className="btn-primary"><Plus className="w-4 h-4" /> Banner qo'shish</button>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {banners.map((banner: any, i: number) => (
            <motion.div key={banner.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="card overflow-hidden hover:border-primary-500/30 transition-all">
              <div className="h-36 bg-gradient-to-br from-primary-900 to-dark-800 flex items-center justify-center relative">
                {banner.image ? <img src={banner.image} alt={banner.title} className="w-full h-full object-cover" /> : <Image className="w-10 h-10 text-slate-600" />}
                <button onClick={() => { if (confirm('O\'chirishni tasdiqlaysizmi?')) deleteMutation.mutate(banner.id); }} className="absolute top-2 right-2 w-7 h-7 bg-red-600/80 hover:bg-red-600 rounded-lg flex items-center justify-center text-white transition-colors">
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
              <div className="p-4">
                <p className="font-semibold text-gray-900">{banner.title}</p>
                {banner.description && <p className="text-sm text-gray-500 mt-1 line-clamp-2">{banner.description}</p>}
                {banner.link && (
                  <a href={banner.link} target="_blank" rel="noreferrer" className="text-xs text-primary-400 hover:underline mt-1 flex items-center gap-1 truncate">
                    <span>🔗</span> {banner.link}
                  </a>
                )}
              </div>
            </motion.div>
          ))}
          {banners.length === 0 && (
            <div className="col-span-3 card p-12 text-center">
              <Image className="w-12 h-12 text-slate-600 mx-auto mb-3" />
              <p className="text-gray-500">Hozircha bannerlar yo'q</p>
            </div>
          )}
        </div>
      )}

      <AnimatePresence>
        {showForm && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={() => setShowForm(false)}>
            <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} exit={{ scale: 0.95 }} className="card p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
              <div className="flex items-center justify-between mb-5">
                <h3 className="font-semibold text-gray-900">Yangi banner</h3>
                <button onClick={() => setShowForm(false)} className="p-1.5 hover:bg-gray-100 rounded-lg text-gray-500"><X className="w-4 h-4" /></button>
              </div>
              <div className="space-y-3">
                <div><label className="block text-xs font-medium text-gray-500 mb-1">Sarlavha *</label><input value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} className="input py-2 text-sm" placeholder="Banner sarlavhasi" /></div>
                <div><label className="block text-xs font-medium text-gray-500 mb-1">Tavsif</label><textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input py-2 text-sm resize-none" rows={2} placeholder="Banner tavsifi" /></div>
                <div><label className="block text-xs font-medium text-gray-500 mb-1">Havola URL (ixtiyoriy)</label><input type="url" value={form.link} onChange={e => setForm(f => ({ ...f, link: e.target.value }))} className="input py-2 text-sm" placeholder="https://example.com/reklama" /></div>
                <div><label className="block text-xs font-medium text-gray-500 mb-1">Rasm</label><input type="file" accept="image/*" onChange={e => setForm(f => ({ ...f, image: e.target.files?.[0] || null }))} className="input py-2 text-sm file:mr-3 file:py-1 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-medium file:bg-primary-600/20 file:text-primary-400" /></div>
              </div>
              <div className="flex gap-3 mt-5">
                <button onClick={() => setShowForm(false)} className="btn-secondary flex-1 justify-center py-2">Bekor</button>
                <button onClick={() => createMutation.mutate()} disabled={createMutation.isPending || !form.title} className="btn-primary flex-1 justify-center py-2">
                  {createMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Yaratish'}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
