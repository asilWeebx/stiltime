import { useState, useRef, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Save, ArrowLeft, Loader2, Upload, X, Image as ImageIcon, Building2, Clock, Sun } from 'lucide-react';
import { salonsAPI, regionsAPI, workingHoursAPI, salonImagesAPI } from '../../api';
import toast from 'react-hot-toast';

type ExistingImage = { id: number; image: string };

const DAY_NAMES = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

type DayHours = {
  day_of_week: number;
  open_time: string;
  close_time: string;
  is_day_off: boolean;
};

function defaultHours(): DayHours[] {
  return DAY_NAMES.map((_, i) => ({
    day_of_week: i,
    open_time: '09:00',
    close_time: '20:00',
    is_day_off: i === 6, // Sunday off by default
  }));
}

export default function SalonFormPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isEdit = !!id;

  const { register, handleSubmit, formState: { errors } } = useForm();

  // Controlled region/district
  const [regionId, setRegionId] = useState('');
  const [districtId, setDistrictId] = useState('');

  // Working hours state
  const [hours, setHours] = useState<DayHours[]>(defaultHours());

  // ── Regions ────────────────────────────────────────────────────────────────
  const { data: regionsResp } = useQuery({
    queryKey: ['regions'],
    queryFn: () => regionsAPI.list().then(r => r.data),
  });
  const regions: Array<{ id: number; name: string }> =
    Array.isArray(regionsResp) ? regionsResp : (regionsResp?.results ?? []);

  // ── Districts (cascade) ────────────────────────────────────────────────────
  const { data: districtsResp } = useQuery({
    queryKey: ['districts', regionId],
    queryFn: () => regionsAPI.districts(Number(regionId)).then(r => r.data),
    enabled: !!regionId,
  });
  const districts: Array<{ id: number; name: string }> =
    Array.isArray(districtsResp) ? districtsResp : (districtsResp?.results ?? []);

  // ── Existing salon ─────────────────────────────────────────────────────────
  const { data: existing } = useQuery({
    queryKey: ['salon', id],
    queryFn: () => salonsAPI.get(Number(id)).then(r => r.data),
    enabled: isEdit,
  });

  // ── Existing working hours ─────────────────────────────────────────────────
  const { data: existingHours } = useQuery({
    queryKey: ['working-hours', id],
    queryFn: () => workingHoursAPI.get(Number(id)).then(r => r.data),
    enabled: isEdit,
  });

  useEffect(() => {
    if (existing) {
      if (existing.region) setRegionId(String(existing.region));
      if (existing.district) setDistrictId(String(existing.district));
    }
  }, [existing]);

  useEffect(() => {
    if (existingHours && Array.isArray(existingHours) && existingHours.length > 0) {
      const merged = defaultHours().map(def => {
        const found = existingHours.find((h: DayHours) => h.day_of_week === def.day_of_week);
        return found ? { ...def, ...found } : def;
      });
      setHours(merged);
    }
  }, [existingHours]);

  // ── Images ─────────────────────────────────────────────────────────────────
  const [logo, setLogo] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);
  const [cover, setCover] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);
  // existing images from API (have id + url, delete via separate endpoint)
  const [existingImages, setExistingImages] = useState<ExistingImage[]>([]);
  // new images queued for upload after salon save
  const [newImages, setNewImages] = useState<File[]>([]);
  const [newImagePreviews, setNewImagePreviews] = useState<string[]>([]);
  const [deletingImgId, setDeletingImgId] = useState<number | null>(null);

  useEffect(() => {
    if (existing) {
      if (!logoPreview && existing.logo) setLogoPreview(existing.logo);
      if (!coverPreview && existing.cover_image) setCoverPreview(existing.cover_image);
    }
  }, [existing]);

  // Load gallery images via dedicated endpoint
  const { data: galleryData, refetch: refetchGallery } = useQuery({
    queryKey: ['salon-images', id],
    queryFn: () => salonImagesAPI.list(Number(id)).then(r => r.data as ExistingImage[]),
    enabled: isEdit,
  });
  useEffect(() => {
    if (galleryData) setExistingImages(galleryData);
  }, [galleryData]);

  const logoRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);
  const imagesRef = useRef<HTMLInputElement>(null);

  const handleLogo = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]; if (!f) return;
    setLogo(f); setLogoPreview(URL.createObjectURL(f));
  };
  const handleCover = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]; if (!f) return;
    setCover(f); setCoverPreview(URL.createObjectURL(f));
  };
  const handleNewImages = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    const slots = 10 - existingImages.length - newImages.length;
    const toAdd = files.slice(0, Math.max(0, slots));
    setNewImages(prev => [...prev, ...toAdd]);
    setNewImagePreviews(prev => [...prev, ...toAdd.map(f => URL.createObjectURL(f))]);
    // reset input so same file can be re-selected
    e.target.value = '';
  };
  const removeNewImage = (idx: number) => {
    setNewImages(prev => prev.filter((_, i) => i !== idx));
    setNewImagePreviews(prev => prev.filter((_, i) => i !== idx));
  };
  const deleteExistingImage = async (img: ExistingImage) => {
    setDeletingImgId(img.id);
    try {
      await salonImagesAPI.delete(Number(id), img.id);
      setExistingImages(prev => prev.filter(i => i.id !== img.id));
      refetchGallery();
    } catch {
      toast.error('Rasmni o\'chirishda xatolik');
    } finally {
      setDeletingImgId(null);
    }
  };

  const handleRegionChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setRegionId(e.target.value);
    setDistrictId('');
  };

  // ── Working hours helpers ──────────────────────────────────────────────────
  const updateHour = (dayIdx: number, field: keyof DayHours, value: string | boolean) => {
    setHours(prev => prev.map(h => h.day_of_week === dayIdx ? { ...h, [field]: value } : h));
  };

  // ── Submit salon ───────────────────────────────────────────────────────────
  const mutation = useMutation({
    mutationFn: async (data: any) => {
      const fd = new FormData();
      ['name', 'type', 'phone', 'instagram', 'telegram', 'description', 'address', 'latitude', 'longitude', 'gender']
        .forEach(k => { if (data[k] !== undefined && data[k] !== '') fd.append(k, data[k]); });
      if (regionId) fd.append('region', regionId);
      if (districtId) fd.append('district', districtId);
      if (logo) fd.append('logo', logo);
      if (cover) fd.append('cover_image', cover);
      if (!isEdit) { fd.append('is_verified', 'true'); fd.append('is_active', 'true'); }

      const salonRes = isEdit
        ? await salonsAPI.update(Number(id), fd)
        : await salonsAPI.create(fd);

      const salonId = salonRes.data.id ?? Number(id);
      await workingHoursAPI.set(salonId, hours);

      // Upload each new gallery image via the dedicated images endpoint
      for (const file of newImages) {
        await salonImagesAPI.upload(salonId, file);
      }

      return salonRes;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['salons'] });
      toast.success(isEdit ? 'Salon yangilandi!' : 'Salon yaratildi!');
      navigate('/salons');
    },
    onError: (e: any) => {
      const msg = e?.response?.data ? JSON.stringify(e.response.data).slice(0, 160) : 'Xatolik yuz berdi';
      toast.error(msg);
    },
  });

  // ── Compute is_open preview ────────────────────────────────────────────────
  const now = new Date();
  const todayIdx = (now.getDay() + 6) % 7; // 0=Mon...6=Sun
  const todayHours = hours[todayIdx];
  const isOpenNow = !todayHours?.is_day_off && (() => {
    if (!todayHours) return false;
    const [oh, om] = todayHours.open_time.split(':').map(Number);
    const [ch, cm] = todayHours.close_time.split(':').map(Number);
    const cur = now.getHours() * 60 + now.getMinutes();
    return cur >= oh * 60 + om && cur <= ch * 60 + cm;
  })();

  return (
    <div className="max-w-3xl space-y-6 animate-fade-in pb-10">
      <button onClick={() => navigate('/salons')} className="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors text-sm">
        <ArrowLeft className="w-4 h-4" /> Salonlar ro'yxati
      </button>

      <form onSubmit={handleSubmit(d => mutation.mutate(d))} className="space-y-5">

        {/* ── Images ── */}
        <div className="card p-6 space-y-5">
          <h2 className="text-base font-semibold text-gray-800 flex items-center gap-2">
            <ImageIcon className="w-4 h-4 text-primary-500" /> Rasmlar
          </h2>
          <div className="grid grid-cols-2 gap-5">
            {[
              { label: 'Logo', preview: logoPreview, ref: logoRef, clear: () => { setLogo(null); setLogoPreview(null); }, icon: Building2, onChange: handleLogo },
              { label: 'Muqova rasmi', preview: coverPreview, ref: coverRef, clear: () => { setCover(null); setCoverPreview(null); }, icon: Upload, onChange: handleCover },
            ].map(({ label, preview, ref, clear, icon: Icon, onChange }) => (
              <div key={label}>
                <label className="block text-sm font-medium text-gray-600 mb-2">{label} <span className="text-gray-400 font-normal">(ixtiyoriy)</span></label>
                <div onClick={() => ref.current?.click()} className="relative cursor-pointer border-2 border-dashed border-gray-200 rounded-2xl overflow-hidden hover:border-primary-400 transition-colors flex items-center justify-center" style={{ height: 120 }}>
                  {preview ? (
                    <>
                      <img src={preview} alt={label} className="w-full h-full object-cover" />
                      <button type="button" onClick={e => { e.stopPropagation(); clear(); }} className="absolute top-2 right-2 w-6 h-6 bg-red-500 rounded-full flex items-center justify-center text-white"><X className="w-3 h-3" /></button>
                    </>
                  ) : (
                    <div className="flex flex-col items-center gap-2 text-gray-400"><Icon className="w-8 h-8" /><span className="text-xs">{label} yuklash</span></div>
                  )}
                </div>
                <input ref={ref} type="file" accept="image/*" className="hidden" onChange={onChange} />
              </div>
            ))}
          </div>
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm font-medium text-gray-600">Qo'shimcha rasmlar <span className="text-gray-400 font-normal">(ixtiyoriy, max 10)</span></label>
              <span className="text-xs text-gray-400">{existingImages.length + newImages.length}/10</span>
            </div>
            <div className="grid grid-cols-5 gap-2">
              {/* Existing images — delete hits the API immediately */}
              {existingImages.map((img) => (
                <div key={`ex-${img.id}`} className="relative rounded-xl overflow-hidden border border-gray-200" style={{ aspectRatio: '1' }}>
                  <img src={img.image} className="w-full h-full object-cover" alt="" />
                  <button
                    type="button"
                    onClick={() => deleteExistingImage(img)}
                    disabled={deletingImgId === img.id}
                    className="absolute top-1 right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center text-white shadow disabled:opacity-60"
                  >
                    {deletingImgId === img.id ? <Loader2 className="w-2.5 h-2.5 animate-spin" /> : <X className="w-3 h-3" />}
                  </button>
                </div>
              ))}
              {/* New images — not yet uploaded, just queued */}
              {newImagePreviews.map((src: string, i: number) => (
                <div key={`new-${i}`} className="relative rounded-xl overflow-hidden border-2 border-dashed border-primary-300" style={{ aspectRatio: '1' }}>
                  <img src={src} className="w-full h-full object-cover" alt="" />
                  <button type="button" onClick={() => removeNewImage(i)} className="absolute top-1 right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center text-white shadow"><X className="w-3 h-3" /></button>
                  <span className="absolute bottom-0 left-0 right-0 text-center text-white text-[9px] bg-primary-500/70 py-0.5">yangi</span>
                </div>
              ))}
              {/* Upload slot */}
              {existingImages.length + newImages.length < 10 && (
                <div onClick={() => imagesRef.current?.click()} className="border-2 border-dashed border-gray-200 rounded-xl flex items-center justify-center cursor-pointer hover:border-primary-400 transition-colors" style={{ aspectRatio: '1' }}>
                  <Upload className="w-5 h-5 text-gray-400" />
                </div>
              )}
            </div>
            <input ref={imagesRef} type="file" accept="image/*" multiple className="hidden" onChange={handleNewImages} />
          </div>
        </div>

        {/* ── Basic info ── */}
        <div className="card p-6 space-y-4">
          <h2 className="text-base font-semibold text-gray-800">Asosiy ma'lumotlar</h2>
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Salon nomi *</label>
              <input {...register('name', { required: 'Nom majburiy' })} defaultValue={existing?.name} className="input" placeholder="Masalan: Style Barbershop" />
              {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name.message as string}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Turi</label>
              <select {...register('type')} defaultValue={existing?.type || 'barbershop'} className="input">
                <option value="barbershop">Sartaroshxona</option>
                <option value="beauty_salon">Go'zallik saloni</option>
                <option value="nail">Tirnoq saloni</option>
                <option value="spa">Spa</option>
                <option value="mixed">Aralash</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Mijozlar</label>
              <select {...register('gender')} defaultValue={existing?.gender || 'unisex'} className="input">
                <option value="unisex">Umumiy</option>
                <option value="male">Erkaklar</option>
                <option value="female">Ayollar</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Telefon</label>
              <input {...register('phone')} defaultValue={existing?.phone} className="input" placeholder="+998 90 123 45 67" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Instagram</label>
              <input {...register('instagram')} defaultValue={existing?.instagram} className="input" placeholder="@username" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Telegram</label>
              <input {...register('telegram')} defaultValue={existing?.telegram} className="input" placeholder="@username" />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Tavsif</label>
              <textarea {...register('description')} defaultValue={existing?.description} className="input resize-none" rows={3} placeholder="Salon haqida qisqacha ma'lumot..." />
            </div>
          </div>
        </div>

        {/* ── Location ── */}
        <div className="card p-6 space-y-4">
          <h2 className="text-base font-semibold text-gray-800">Manzil</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Viloyat</label>
              <select value={regionId} onChange={handleRegionChange} className="input">
                <option value="">— Tanlang —</option>
                {regions.map(r => <option key={r.id} value={String(r.id)}>{r.name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">
                Tuman / shahar {!regionId && <span className="text-gray-400 font-normal">(avval viloyat tanlang)</span>}
              </label>
              <select value={districtId} onChange={e => setDistrictId(e.target.value)} disabled={!regionId} className="input disabled:opacity-50 disabled:cursor-not-allowed">
                <option value="">— Tanlang —</option>
                {districts.map(d => <option key={d.id} value={String(d.id)}>{d.name}</option>)}
              </select>
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-600 mb-1.5">To'liq manzil</label>
              <input {...register('address')} defaultValue={existing?.address} className="input" placeholder="Ko'cha, uy raqami..." />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Kenglik <span className="text-gray-400 font-normal">(latitude)</span></label>
              <input {...register('latitude')} defaultValue={existing?.latitude} type="number" step="any" className="input font-mono text-sm" placeholder="41.2995" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1.5">Uzunlik <span className="text-gray-400 font-normal">(longitude)</span></label>
              <input {...register('longitude')} defaultValue={existing?.longitude} type="number" step="any" className="input font-mono text-sm" placeholder="69.2401" />
            </div>
          </div>
          <p className="text-xs text-gray-400 bg-blue-50 border border-blue-100 rounded-xl px-4 py-3">
            💡 Koordinatalarni Google Maps yoki Yandex Maps dan olishingiz mumkin.
          </p>
        </div>

        {/* ── Working hours ── */}
        <div className="card p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-semibold text-gray-800 flex items-center gap-2">
              <Clock className="w-4 h-4 text-primary-500" /> Ish vaqti
            </h2>
            <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold ${isOpenNow ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>
              <Sun className="w-3 h-3" />
              {isOpenNow ? 'Hozir ochiq' : 'Hozir yopiq'}
            </div>
          </div>

          <div className="space-y-2">
            {hours.map((h, i) => (
              <div key={i} className={`grid grid-cols-[120px_1fr_1fr_auto] gap-3 items-center px-4 py-3 rounded-xl border transition-colors ${h.is_day_off ? 'bg-gray-50 border-gray-100' : 'bg-white border-gray-200'} ${todayIdx === i ? 'ring-2 ring-primary-200' : ''}`}>
                <div className="flex items-center gap-2">
                  <span className={`text-sm font-medium ${h.is_day_off ? 'text-gray-400' : 'text-gray-700'}`}>{DAY_NAMES[i]}</span>
                  {todayIdx === i && <span className="text-xs text-primary-500 font-semibold">bugun</span>}
                </div>
                <div>
                  <label className="text-xs text-gray-400 mb-0.5 block">Ochilish</label>
                  <input
                    type="time"
                    value={h.open_time}
                    onChange={e => updateHour(i, 'open_time', e.target.value)}
                    disabled={h.is_day_off}
                    className="input py-1.5 text-sm disabled:opacity-40"
                  />
                </div>
                <div>
                  <label className="text-xs text-gray-400 mb-0.5 block">Yopilish</label>
                  <input
                    type="time"
                    value={h.close_time}
                    onChange={e => updateHour(i, 'close_time', e.target.value)}
                    disabled={h.is_day_off}
                    className="input py-1.5 text-sm disabled:opacity-40"
                  />
                </div>
                <div className="flex flex-col items-center gap-1 pt-4">
                  <label className="text-xs text-gray-400 whitespace-nowrap">Dam olish</label>
                  <button
                    type="button"
                    onClick={() => updateHour(i, 'is_day_off', !h.is_day_off)}
                    className={`w-10 h-5 rounded-full transition-colors relative ${h.is_day_off ? 'bg-red-400' : 'bg-gray-200'}`}
                  >
                    <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${h.is_day_off ? 'translate-x-5' : 'translate-x-0.5'}`} />
                  </button>
                </div>
              </div>
            ))}
          </div>
          <p className="text-xs text-gray-400">
            Platforma ish vaqtiga qarab Ochiq/Yopiq holatini avtomatik aniqlaydi.
          </p>
        </div>

        {/* ── Actions ── */}
        <div className="flex gap-3">
          <button type="button" onClick={() => navigate('/salons')} className="btn-secondary flex-1 justify-center py-3">
            Bekor qilish
          </button>
          <button type="submit" disabled={mutation.isPending} className="btn-primary flex-1 justify-center py-3">
            {mutation.isPending
              ? <><Loader2 className="w-4 h-4 animate-spin" /> Saqlanmoqda...</>
              : <><Save className="w-4 h-4" /> {isEdit ? 'Yangilash' : 'Saqlash'}</>}
          </button>
        </div>

      </form>
    </div>
  );
}
