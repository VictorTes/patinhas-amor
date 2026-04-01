import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
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

  return (
    <div className="min-h-screen flex flex-col bg-red-50/30">
      
      <main className="flex-grow py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <FadeIn direction="down">
            <div className="bg-white border-l-8 border-red-500 p-6 md:p-8 mb-10 rounded-2xl shadow-xl shadow-red-100/50">
              <h1 className="text-3xl md:text-4xl font-black text-red-900 mb-3 flex items-center gap-3">
                <motion.span 
                  animate={{ scale: [1, 1.2, 1] }} 
                  transition={{ repeat: Infinity, duration: 1.5 }}
                >
                  ⚠️
                </motion.span> 
                Animais Desaparecidos
              </h1>
              <p className="text-red-700 text-lg md:text-xl leading-relaxed max-w-3xl">
                Estes amiguinhos estão longe de casa e suas famílias estão desesperadas. 
                Se você os viu, utilize os contatos abaixo imediatamente.
              </p>
            </div>
          </FadeIn>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <motion.div 
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
                className="h-14 w-14 border-4 border-red-600 border-t-transparent rounded-full mb-4"
              />
              <p className="text-red-600 font-medium animate-pulse">Carregando alertas urgentes...</p>
            </div>
          ) : (
            <FadeIn delay={0.2}>
              <AnimalGrid
                animals={animals}
                variant="urgent"
                onAnimalClick={(animal) => setSelectedAnimal(animal)}
                emptyMessage="Graças a Deus, nenhum animal desaparecido registrado no momento."
              />
            </FadeIn>
          )}
        </div>
      </main>

      {/* MODAL DE DETALHES ANIMADO */}
      <AnimatePresence>
        {selectedAnimal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/80 backdrop-blur-md"
            onClick={() => setSelectedAnimal(null)}
          >
            <motion.div 
              initial={{ scale: 0.9, y: 50, opacity: 0 }}
              animate={{ scale: 1, y: 0, opacity: 1 }}
              exit={{ scale: 0.9, y: 50, opacity: 0 }}
              className="bg-white rounded-[2.5rem] shadow-2xl max-w-md w-full overflow-hidden border border-red-100"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="relative aspect-square bg-slate-100 overflow-hidden">
                <motion.img 
                  initial={{ scale: 1.2 }}
                  animate={{ scale: 1 }}
                  transition={{ duration: 0.6 }}
                  src={selectedAnimal.imageUrl || ANIMAL_PLACEHOLDER_IMAGE} 
                  alt={selectedAnimal.name} 
                  className="w-full h-full object-cover"
                />
                
                <button 
                  onClick={() => setSelectedAnimal(null)}
                  className="absolute top-5 right-5 bg-white/20 hover:bg-white/40 text-white w-12 h-12 rounded-full flex items-center justify-center backdrop-blur-xl transition-all shadow-lg border border-white/30"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>

                <div className="absolute bottom-5 left-5 bg-red-600 text-white px-5 py-2 rounded-2xl text-xs font-black uppercase tracking-widest shadow-xl flex items-center gap-3">
                  <span className="relative flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-white"></span>
                  </span>
                  Alerta Crítico
                </div>
              </div>
              
              <div className="p-8">
                <div className="flex justify-between items-center mb-6">
                  <div>
                    <h2 className="text-3xl font-black text-slate-900 tracking-tighter italic">
                      {selectedAnimal.name.toUpperCase()}
                    </h2>
                    <p className="text-red-600 font-bold flex items-center gap-2">
                      {selectedAnimal.species} • {selectedAnimal.sex}
                    </p>
                  </div>
                  <div className="bg-red-50 text-red-700 px-4 py-2 rounded-xl text-xs font-black border border-red-100">
                    PORTE {selectedAnimal.size.toUpperCase()}
                  </div>
                </div>

                <div className="mb-8">
                  <h4 className="font-black text-slate-400 mb-2 text-[10px] uppercase tracking-[0.2em]">Informações Gerais</h4>
                  <div className="bg-slate-50 p-5 rounded-[1.5rem] border border-slate-100 text-slate-700 leading-relaxed font-medium">
                    {selectedAnimal.description || "O tutor não forneceu detalhes adicionais, mas qualquer pista é valiosa."}
                  </div>
                </div>

                {selectedAnimal.adopterPhone && (
                  <motion.div 
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.3 }}
                    className="bg-red-600 p-6 rounded-[2rem] text-white shadow-xl shadow-red-200"
                  >
                    <p className="text-[10px] font-black uppercase tracking-widest opacity-80 mb-3 text-center">Falar diretamente com o tutor</p>
                    <div className="flex items-center justify-center gap-4 mb-5">
                       <span className="text-3xl">📞</span>
                       <span className="text-2xl font-black tracking-tighter">
                         {formatPhoneNumber(selectedAnimal.adopterPhone)}
                       </span>
                    </div>
                    <motion.a 
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      href={`tel:${selectedAnimal.adopterPhone.replace(/\D/g, '')}`} 
                      className="block w-full py-4 bg-white text-red-600 font-black rounded-2xl text-center shadow-lg transition-colors uppercase text-sm tracking-widest"
                    >
                      Ligar Agora
                    </motion.a>
                  </motion.div>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <footer className="bg-slate-950 text-slate-500 py-16 border-t border-slate-900">
        <div className="max-w-7xl mx-auto px-4 text-center">
          <div className="flex items-center justify-center gap-3 mb-6">
            <span className="text-3xl">🐾</span>
            <span className="text-2xl font-black text-white tracking-tighter">Patinhas e Amor</span>
          </div>
          <p className="max-w-md mx-auto text-sm leading-relaxed mb-8">
            Nossa missão é reunir famílias e garantir que nenhum animal sofra sozinho nas ruas.
          </p>
          <div className="h-px w-20 bg-slate-800 mx-auto mb-8" />
          <p className="text-[10px] font-bold uppercase tracking-widest text-slate-600">
            © 2026 Porto União • Santa Catarina
          </p>
        </div>
      </footer>
    </div>
  );
}