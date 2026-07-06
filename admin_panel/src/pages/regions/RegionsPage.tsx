import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { MapPin, ChevronDown, ChevronRight } from 'lucide-react';
import { regionsAPI } from '../../api';
import LoadingSpinner from '../../components/common/LoadingSpinner';

export default function RegionsPage() {
  const [expanded, setExpanded] = useState<number | null>(null);
  const { data: regions, isLoading } = useQuery({ queryKey: ['regions'], queryFn: () => regionsAPI.list().then(r => r.data?.results ?? r.data) });
  const { data: districts } = useQuery({ queryKey: ['districts', expanded], queryFn: () => regionsAPI.districts(expanded || undefined).then(r => r.data?.results ?? r.data), enabled: !!expanded });

  return (
    <div className="space-y-6 animate-fade-in max-w-2xl">
      <p className="text-sm text-gray-500">O'zbekiston viloyatlari va tumanlari</p>
      {isLoading ? <LoadingSpinner /> : (
        <div className="space-y-2">
          {(regions || []).map((region: any, i: number) => (
            <motion.div key={region.id} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }} className="card overflow-hidden">
              <button onClick={() => setExpanded(expanded === region.id ? null : region.id)} className="w-full flex items-center gap-3 px-5 py-4 hover:bg-gray-100 transition-colors text-left">
                <div className="w-8 h-8 rounded-lg bg-primary-600/20 border border-primary-500/30 flex items-center justify-center">
                  <MapPin className="w-4 h-4 text-primary-400" />
                </div>
                <span className="font-medium text-gray-900 flex-1">{region.name}</span>
                {expanded === region.id ? <ChevronDown className="w-4 h-4 text-gray-500" /> : <ChevronRight className="w-4 h-4 text-gray-500" />}
              </button>
              {expanded === region.id && (
                <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} className="border-t border-gray-200 overflow-hidden">
                  <div className="px-5 py-3 grid grid-cols-2 gap-2">
                    {(districts || []).filter((d: any) => d.region === region.id).map((district: any) => (
                      <div key={district.id} className="flex items-center gap-2 py-1.5">
                        <span className="w-1.5 h-1.5 rounded-full bg-primary-500 flex-shrink-0" />
                        <span className="text-sm text-gray-700">{district.name}</span>
                      </div>
                    ))}
                  </div>
                </motion.div>
              )}
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
