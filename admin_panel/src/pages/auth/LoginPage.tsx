import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Sparkles, Phone, KeyRound, Loader2, ArrowRight } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { authAPI } from '../../api';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuthStore();
  const navigate = useNavigate();

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!phone.trim()) return;
    setLoading(true);
    try {
      await authAPI.sendOTP(phone);
      setStep('otp');
      toast.success('OTP kod yuborildi');
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otp.trim()) return;
    setLoading(true);
    try {
      const { data } = await authAPI.verifyOTP(phone, otp);
      if (data.user.role !== 'superadmin') {
        toast.error('Faqat SuperAdmin kirishi mumkin');
        return;
      }
      login(data.user, data.tokens);
      navigate('/');
      toast.success(`Xush kelibsiz, ${data.user.full_name || 'Admin'}!`);
    } catch (err: any) {
      toast.error(err.response?.data?.code?.[0] || 'Noto\'g\'ri kod');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background glow */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -left-40 w-96 h-96 bg-primary-600/20 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-purple-600/20 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-primary-900/10 rounded-full blur-3xl" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-md relative z-10"
      >
        {/* Card */}
        <div className="bg-white/90 backdrop-blur-xl border border-gray-200 rounded-3xl p-8 shadow-2xl">
          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-500 via-purple-600 to-primary-800 flex items-center justify-center mb-4 shadow-lg shadow-primary-500/30">
              <Sparkles className="w-8 h-8 text-white" />
            </div>
            <h1 className="font-display text-3xl font-bold text-gray-900">StilTime</h1>
            <p className="text-primary-400 text-sm font-medium mt-1">SuperAdmin Panel</p>
          </div>

          <AnimatePresence mode="wait">
            {step === 'phone' ? (
              <motion.form
                key="phone"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                onSubmit={handleSendOTP}
                className="space-y-5"
              >
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Telefon raqam</label>
                  <div className="relative">
                    <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="+998 90 123 45 67"
                      className="input pl-12"
                      required
                      autoFocus
                    />
                  </div>
                </div>

                <button type="submit" disabled={loading} className="btn-primary w-full justify-center py-3 text-base">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <><span>OTP yuborish</span><ArrowRight className="w-5 h-5" /></>}
                </button>
              </motion.form>
            ) : (
              <motion.form
                key="otp"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                onSubmit={handleVerifyOTP}
                className="space-y-5"
              >
                <div className="text-center mb-4">
                  <p className="text-gray-500 text-sm">
                    <span className="text-primary-400 font-medium">{phone}</span> ga kod yuborildi
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">OTP Kod</label>
                  <div className="relative">
                    <KeyRound className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input
                      type="text"
                      value={otp}
                      onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      placeholder="• • • • • •"
                      className="input pl-12 text-center text-2xl tracking-[0.5em] font-bold"
                      maxLength={6}
                      autoFocus
                      required
                    />
                  </div>
                </div>

                <button type="submit" disabled={loading || otp.length < 4} className="btn-primary w-full justify-center py-3 text-base">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <><span>Tasdiqlash</span><ArrowRight className="w-5 h-5" /></>}
                </button>

                <button
                  type="button"
                  onClick={() => setStep('phone')}
                  className="w-full text-center text-sm text-gray-400 hover:text-gray-700 transition-colors py-1"
                >
                  ← Orqaga qaytish
                </button>
              </motion.form>
            )}
          </AnimatePresence>
        </div>

        <p className="text-center text-xs text-gray-400 mt-6">
          StilTime v1.0 — Beauty & Barbershop Booking Platform
        </p>
      </motion.div>
    </div>
  );
}
