import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useMutation } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Bell, Send, Users, Scissors, Globe, Loader2 } from 'lucide-react';
import { notificationsAPI } from '../../api';
import toast from 'react-hot-toast';

const targets = [
  { value: 'all', label: 'Hamma', icon: Globe, color: 'from-purple-500 to-primary-700' },
  { value: 'customers', label: 'Mijozlar', icon: Users, color: 'from-blue-500 to-cyan-600' },
  { value: 'barbers', label: 'Sartaroshlar', icon: Scissors, color: 'from-amber-500 to-orange-600' },
];

export default function NotificationsPage() {
  const [target, setTarget] = useState('all');
  const { register, handleSubmit, reset, watch, formState: { errors } } = useForm<{ title: string; body: string }>();

  const sendMutation = useMutation({
    mutationFn: (data: any) => notificationsAPI.broadcast({ ...data, target }),
    onSuccess: () => {
      reset();
      toast.success('✅ Bildirishnoma yuborildi!');
    },
    onError: () => toast.error('Xatolik yuz berdi'),
  });

  const title = watch('title', '');
  const body = watch('body', '');

  return (
    <div className="max-w-3xl space-y-6 animate-fade-in">
      <div className="card p-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-primary-600/20 border border-primary-500/30 flex items-center justify-center">
            <Bell className="w-5 h-5 text-primary-400" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">Push Bildirishnoma Yuborish</h3>
            <p className="text-sm text-gray-500">Firebase Cloud Messaging orqali yuboriladi</p>
          </div>
        </div>

        {/* Target Selection */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-3">Kimga yuborish</label>
          <div className="grid grid-cols-3 gap-3">
            {targets.map(({ value, label, icon: Icon, color }) => (
              <button
                key={value}
                onClick={() => setTarget(value)}
                className={`p-4 rounded-xl border transition-all duration-200 flex flex-col items-center gap-2 ${
                  target === value
                    ? 'border-primary-500/50 bg-primary-600/10'
                    : 'border-gray-200 bg-gray-100 hover:border-gray-200'
                }`}
              >
                <div className={`w-10 h-10 rounded-lg bg-gradient-to-br ${color} flex items-center justify-center`}>
                  <Icon className="w-5 h-5 text-white" />
                </div>
                <span className={`text-sm font-medium ${target === value ? 'text-primary-300' : 'text-gray-500'}`}>
                  {label}
                </span>
              </button>
            ))}
          </div>
        </div>

        <form onSubmit={handleSubmit(d => sendMutation.mutate(d))} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Sarlavha</label>
            <input
              {...register('title', { required: true })}
              placeholder="Bildirishnoma sarlavhasi"
              className="input"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Matn</label>
            <textarea
              {...register('body', { required: true })}
              placeholder="Bildirishnoma matni..."
              className="input resize-none"
              rows={4}
            />
          </div>

          {/* Preview */}
          {(title || body) && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-gray-100 border border-gray-200 rounded-2xl p-4"
            >
              <p className="text-xs text-gray-400 mb-3">Ko'rinishi</p>
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-purple-700 flex items-center justify-center flex-shrink-0">
                  <Bell className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900 text-sm">{title || 'Sarlavha'}</p>
                  <p className="text-sm text-gray-500 mt-0.5">{body || 'Matn...'}</p>
                </div>
              </div>
            </motion.div>
          )}

          <button
            type="submit"
            disabled={sendMutation.isPending}
            className="btn-primary w-full justify-center py-3 text-base"
          >
            {sendMutation.isPending
              ? <><Loader2 className="w-5 h-5 animate-spin" /> Yuborilmoqda...</>
              : <><Send className="w-5 h-5" /> Yuborish</>
            }
          </button>
        </form>
      </div>
    </div>
  );
}
