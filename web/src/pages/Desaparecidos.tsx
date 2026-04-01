import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { Variants } from 'framer-motion';
import type { Animal } from '../types';
import { getAnimalsByStatus, ANIMAL_PLACEHOLDER_IMAGE } from '../services/firebaseService';
import { AnimalGrid } from '../components/AnimalGrid';
import { formatPhoneNumber } from '../utils/formatPhoneNumber';
import { FadeIn } from '../components/FadeIn';

export function Desaparecidos() {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedAnimal, setSelectedAnimal] = useState<Animal | null>(null);

  useEffect(() => {
    async function fetchAnimals() {
      try {
        const data = await getAnimalsByStatus('missing');
        setAnimals(data);
      } catch (error) {
        console.error('Error fetching animals:', error);
      } finally {
        setLoading(false);
      }
    }
    fetchAnimals();
  }, []);

  // Variantes otimizadas para performance máxima (GPU accelerated)
  const modalVariants: Variants = {
    hidden: { 
      opacity: 0, 
      scale: 0.98,
      y: 10,
    },
    visible: { 
      opacity: 1, 
      scale: 1,
      y: 0,
      transition: { 
        duration: 0.25,
        ease: [0.4, 0, 0.2, 1] // Ease-out fluido e leve
      }
    },
    exit: { 
      opacity: 0, 
      scale: 0.98,
      transition: { duration: 0.15 } 
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <main className="flex-grow py-6 md:py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <FadeIn direction="down">
            <div className="bg-white border-l-4 md:border-l-8 border-rose-500 p-5 md:p-8 mb-8 rounded-2xl shadow-sm border border-slate-100">
              <h1 className="text-2xl md:text-4xl font-black text-slate-800 mb-2 flex items-center gap-2 md:gap-3">
                <span className="text-rose-500 animate-pulse text-xl md:text-3xl">●</span> 
                Animais Desaparecidos
              </h1>
              <p className="text-slate-600 text-sm md:text-lg leading-relaxed max-w-3xl">
                Ajude-nos a reunir essas famílias. Qualquer informação pode salvar um amiguinho.
              </p>
            </div>
          </FadeIn>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="h-10 w-10 border-4 border-rose-500 border-t-transparent rounded-full animate-spin mb-4" />
              <p className="text-slate-400 font-medium italic text-sm">Sincronizando alertas...</p>
            </div>
          ) : (
            <FadeIn delay={0.2}>
              <AnimalGrid
                animals={animals}
                variant="urgent"
                onAnimalClick={(animal) => setSelectedAnimal(animal)}
                emptyMessage="Nenhum animal desaparecido registrado no momento."
              />
            </FadeIn>
          )}
        </div>
      </main>

      <AnimatePresence>
        {selectedAnimal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            {/* Overlay - Removido backdrop-blur para estabilizar o FPS */}
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedAnimal(null)}
              className="absolute inset-0 bg-slate-900/60"
            />

            {/* Modal Card - Centralizado e Otimizado */}
            <motion.div 
              variants={modalVariants}
              initial="hidden"
              animate="visible"
              exit="exit"
              className="relative bg-white w-full max-w-lg rounded-[2.5rem] shadow-2xl overflow-hidden transform-gpu will-change-transform"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="relative aspect-[4/3] md:aspect-square bg-slate-200">
                <img 
                  src={selectedAnimal.imageUrl || ANIMAL_PLACEHOLDER_IMAGE} 
                  alt={selectedAnimal.name} 
                  className="w-full h-full object-cover"
                />
                
                <button 
                  onClick={() => setSelectedAnimal(null)}
                  className="absolute top-4 right-4 bg-black/40 hover:bg-black/60 text-white w-10 h-10 rounded-full flex items-center justify-center transition-colors z-10"
                >
                  ✕
                </button>

                <div className="absolute bottom-4 left-4 bg-rose-500 text-white px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest shadow-lg">
                  Urgente
                </div>
              </div>
              
              <div className="p-6 md:p-8 max-h-[60vh] overflow-y-auto scrollbar-hide">
                <div className="flex justify-between items-start mb-6">
                  <div className="space-y-1">
                    <h2 className="text-2xl md:text-3xl font-black text-slate-800 tracking-tight leading-none uppercase">
                      {selectedAnimal.name}
                    </h2>
                    <p className="text-rose-500 font-bold text-sm">
                      {selectedAnimal.species} • {selectedAnimal.sex}
                    </p>
                  </div>
                  <div className="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[10px] font-black border border-slate-200 uppercase">
                    {selectedAnimal.size}
                  </div>
                </div>

                <div className="space-y-4 mb-8">
                  <h4 className="font-black text-slate-400 text-[10px] uppercase tracking-[0.2em]">Sobre o animal</h4>
                  <p className="text-slate-600 text-sm md:text-base leading-relaxed italic">
                    "{selectedAnimal.description || "Nenhuma descrição detalhada fornecida."}"
                  </p>
                </div>

                {selectedAnimal.adopterPhone && (
                  <div className="space-y-3">
                    <div className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100">
                      <div className="flex-1">
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider">Contato Tutor</p>
                        <p className="text-lg font-black text-slate-800 leading-tight">
                          {formatPhoneNumber(selectedAnimal.adopterPhone)}
                        </p>
                      </div>
                      <span className="text-2xl ml-4 opacity-30">📞</span>
                    </div>
                    
                    <motion.a 
                      whileTap={{ scale: 0.98 }}
                      href={`tel:${selectedAnimal.adopterPhone.replace(/\D/g, '')}`} 
                      className="flex items-center justify-center w-full py-4 bg-rose-500 hover:bg-rose-600 text-white font-black rounded-2xl shadow-xl shadow-rose-100 transition-all text-sm uppercase tracking-[0.1em]"
                    >
                      Ligar para Informar
                    </motion.a>
                  </div>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <footer className="bg-slate-900 text-slate-500 py-10 mt-auto">
        <div className="max-w-7xl mx-auto px-4 text-center">
          <p className="text-[10px] font-black uppercase tracking-[0.3em] text-white/50 mb-2">Patinhas e Amor</p>
          <p className="text-[10px] opacity-40 uppercase tracking-widest">© 2026 • Porto União</p>
        </div>
      </footer>
    </div>
  );
}