import { motion } from 'framer-motion';
import { useAuthStore } from '../../store/authStore';
import { Shield, Bell, Globe, Palette, Database, Code } from 'lucide-react';

export default function SettingsPage() {
  const { user } = useAuthStore();

  const sections = [
    { icon: Shield, title: 'Admin ma\'lumotlari', color: 'from-purple-500 to-primary-700', items: [
      { label: 'Telefon', value: user?.phone || '—' },
      { label: 'Ism', value: user?.full_name || '—' },
      { label: 'Rol', value: 'SuperAdmin' },
    ]},
    { icon: Database, title: 'Tizim', color: 'from-blue-500 to-cyan-600', items: [
      { label: 'Django versiya', value: '4.2.16' },
      { label: 'DRF versiya', value: '3.15.2' },
      { label: 'Database', value: 'SQLite3 (dev) / PostgreSQL (prod)' },
    ]},
    { icon: Code, title: 'API', color: 'from-emerald-500 to-teal-600', items: [
      { label: 'Swagger', value: '/api/docs/' },
      { label: 'ReDoc', value: '/api/redoc/' },
      { label: 'Base URL', value: '/api/v1/' },
    ]},
  ];

  return (
    <div className="max-w-2xl space-y-6 animate-fade-in">
      {sections.map((section, i) => (
        <motion.div key={section.title} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="card overflow-hidden">
          <div className={`h-1 bg-gradient-to-r ${section.color}`} />
          <div className="p-5">
            <div className="flex items-center gap-3 mb-4">
              <div className={`w-9 h-9 rounded-xl bg-gradient-to-br ${section.color} flex items-center justify-center`}>
                <section.icon className="w-4 h-4 text-white" />
              </div>
              <h3 className="font-semibold text-gray-900">{section.title}</h3>
            </div>
            <div className="space-y-2">
              {section.items.map(item => (
                <div key={item.label} className="flex items-center justify-between py-2 border-b border-gray-200 last:border-0">
                  <span className="text-sm text-gray-500">{item.label}</span>
                  <span className="text-sm font-medium text-gray-800">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        </motion.div>
      ))}

      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="card p-5">
        <h3 className="font-semibold text-gray-900 mb-3">Tezkor havolalar</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: 'Swagger UI', href: 'http://localhost:8000/api/docs/', color: 'text-emerald-400' },
            { label: 'Django Admin', href: 'http://localhost:8000/admin/', color: 'text-amber-400' },
            { label: 'ReDoc', href: 'http://localhost:8000/api/redoc/', color: 'text-blue-400' },
            { label: 'API Schema', href: 'http://localhost:8000/api/schema/', color: 'text-primary-400' },
          ].map(link => (
            <a key={link.label} href={link.href} target="_blank" rel="noopener noreferrer" className={`flex items-center gap-2 px-4 py-3 rounded-xl bg-gray-100 border border-gray-200 hover:border-gray-200 transition-all text-sm font-medium ${link.color}`}>
              <Code className="w-4 h-4" /> {link.label}
            </a>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
