import { useRef, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Edit, Trash2, Loader2, X, Upload, ImageIcon } from 'lucide-react';
import { categoriesAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';
import toast from 'react-hot-toast';

const GENDERS = [
  { value: 'unisex', label: 'Umumiy' },
  { value: 'male',   label: 'Erkaklar' },
  { value: 'female', label: 'Ayollar' },
];

const genderBadge = (g: string) => {
  if (g === 'male')   return <span className="text-xs font-semibold text-blue-500 bg-blue-50 px-2 py-0.5 rounded-full">Erkaklar</span>;
  if (g === 'female') return <span className="text-xs font-semibold text-pink-500 bg-pink-50 px-2 py-0.5 rounded-full">Ayollar</span>;
  return <span className="text-xs font-semibold text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">Umumiy</span>;
};

const defaultForm = () => ({ name: '', name_uz: '', name_ru: '', name_en: '', gender: 'unisex', order: 0 });

export default function CategoriesPage() {
  const [showForm, setShowForm]   = useState(false);
  const [editing, setEditing]     = useState<any>(null);
  const [form, setForm]           = useState(defaultForm());
  const [iconFile, setIconFile]   = useState<File | null>(null);
  const [iconPreview, setIconPreview] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['categories'],
    queryFn: () => categoriesAPI.list().then(r => r.data?.results ?? r.data),
  });

  const saveMutation = useMutation({
    mutationFn: (fd: FormData) =>
      editing ? categoriesAPI.update(editing.id, fd) : categoriesAPI.create(fd),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['categories'] });
      closeForm();
      toast.success(editing ? 'Yangilandi' : 'Yaratildi');
    },
    onError: () => toast.error('Xatolik'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => categoriesAPI.delete(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); toast.success("O'chirildi"); },
  });

  const openEdit = (cat: any) => {
    setEditing(cat);
    setForm({ name: cat.name, name_uz: cat.name_uz || '', name_ru: cat.name_ru || '', name_en: cat.name_en || '', gender: cat.gender || 'unisex', order: cat.order || 0 });
    setIconFile(null);
    setIconPreview(cat.icon || null);
    setShowForm(true);
  };

  const closeForm = () => {
    setShowForm(false);
    setEditing(null);
    setForm(defaultForm());
    setIconFile(null);
    setIconPreview(null);
  };

  const onFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIconFile(file);
    setIconPreview(URL.createObjectURL(file));
  };

  const handleSave = () => {
    if (!form.name) return;
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, String(v)));
    if (iconFile) fd.append('icon', iconFile);
    saveMutation.mutate(fd);
  };

  const cats: any[] = data?.results || data || [];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-gray-900">Kategoriyalar</h2>
          <p className="text-sm text-gray-400">{cats.length} ta kategoriya</p>
        </div>
        <button
          onClick={() => { setEditing(null); setForm(defaultForm()); setIconFile(null); setIconPreview(null); setShowForm(true); }}
          className="btn-primary"
        >
          <Plus className="w-4 h-4" /> Kategoriya qo'shish
        </button>
      </div>

      {isLoading ? <LoadingSpinner /> : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {cats.map((cat: any, i: number) => (
            <motion.div
              key={cat.id}
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.04 }}
              className="card p-4 flex items-center gap-4 hover:border-primary-500/30 transition-all duration-200"
            >
              {/* Icon */}
              <div className="w-14 h-14 rounded-2xl bg-gray-100 border border-gray-200 flex-shrink-0 overflow-hidden">
                {cat.icon
                  ? <img src={cat.icon} alt={cat.name} className="w-full h-full object-cover" />
                  : <div className="w-full h-full flex items-center justify-center"><ImageIcon className="w-6 h-6 text-gray-300" /></div>
                }
              </div>

              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 truncate">{cat.name}</p>
                <div className="flex items-center gap-2 mt-1">
                  {genderBadge(cat.gender)}
                  {cat.name_uz && <p className="text-xs text-gray-400 truncate">{cat.name_uz}</p>}
                </div>
              </div>

              <div className="flex gap-1.5">
                <button onClick={() => openEdit(cat)} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-500 hover:text-primary-400 transition-colors">
                  <Edit className="w-4 h-4" />
                </button>
                <button
                  onClick={() => { if (confirm("O'chirishni tasdiqlaysizmi?")) deleteMutation.mutate(cat.id); }}
                  className="p-1.5 rounded-lg hover:bg-red-50 text-gray-500 hover:text-red-400 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Form modal */}
      <AnimatePresence>
        {showForm && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={closeForm}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }}
              className="card p-6 w-full max-w-md max-h-[90vh] overflow-y-auto"
              onClick={e => e.stopPropagation()}
            >
              <div className="flex items-center justify-between mb-5">
                <h3 className="font-semibold text-gray-900">{editing ? 'Kategoriyani tahrirlash' : 'Yangi kategoriya'}</h3>
                <button onClick={closeForm} className="p-1.5 hover:bg-gray-100 rounded-lg text-gray-500"><X className="w-4 h-4" /></button>
              </div>

              <div className="space-y-4">
                {/* Icon upload */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2">Icon rasm</label>
                  <div className="flex items-center gap-3">
                    <div
                      className="w-16 h-16 rounded-2xl bg-gray-100 border-2 border-dashed border-gray-200 flex items-center justify-center overflow-hidden cursor-pointer hover:border-primary-400 transition-colors flex-shrink-0"
                      onClick={() => fileRef.current?.click()}
                    >
                      {iconPreview
                        ? <img src={iconPreview} alt="icon" className="w-full h-full object-cover" />
                        : <Upload className="w-6 h-6 text-gray-300" />
                      }
                    </div>
                    <div>
                      <button
                        type="button"
                        onClick={() => fileRef.current?.click()}
                        className="btn-secondary text-sm px-3 py-1.5"
                      >
                        <Upload className="w-3.5 h-3.5" />
                        {iconPreview ? 'O\'zgartirish' : 'Yuklash'}
                      </button>
                      <p className="text-xs text-gray-400 mt-1">PNG, JPG — max 2MB</p>
                      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFileChange} />
                    </div>
                  </div>
                </div>

                {/* Gender */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2">Jins (filter uchun)</label>
                  <div className="flex gap-2">
                    {GENDERS.map(g => (
                      <button
                        key={g.value}
                        type="button"
                        onClick={() => setForm(f => ({ ...f, gender: g.value }))}
                        className={`flex-1 py-2 rounded-xl text-sm font-semibold border transition-all ${
                          form.gender === g.value
                            ? 'bg-[#003366] border-[#003366] text-white'
                            : 'bg-white border-gray-200 text-gray-500 hover:border-gray-300'
                        }`}
                      >
                        {g.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Name fields */}
                {([['name', 'Nomi (asosiy) *'], ['name_uz', "O'zbekcha"], ['name_ru', 'Ruscha'], ['name_en', 'Inglizcha']] as const).map(([key, label]) => (
                  <div key={key}>
                    <label className="block text-xs font-medium text-gray-500 mb-1">{label}</label>
                    <input
                      value={(form as any)[key]}
                      onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                      className="input py-2 text-sm"
                      placeholder={label}
                    />
                  </div>
                ))}

                {/* Order */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Tartib raqami</label>
                  <input
                    type="number"
                    value={form.order}
                    onChange={e => setForm(f => ({ ...f, order: Number(e.target.value) }))}
                    className="input py-2 text-sm"
                  />
                </div>
              </div>

              <div className="flex gap-3 mt-5">
                <button onClick={closeForm} className="btn-secondary flex-1 justify-center py-2">Bekor</button>
                <button
                  onClick={handleSave}
                  disabled={saveMutation.isPending || !form.name}
                  className="btn-primary flex-1 justify-center py-2"
                >
                  {saveMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Saqlash'}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
