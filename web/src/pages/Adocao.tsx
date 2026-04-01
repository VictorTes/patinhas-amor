import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { Variants } from 'framer-motion';
import type { Animal } from '../types';
import { getAnimalsByStatus, ANIMAL_PLACEHOLDER_IMAGE } from '../services/firebaseService';
import { AnimalGrid } from '../components/AnimalGrid';
import { FadeIn } from '../components/FadeIn';

export function Adocao() {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [filteredAnimals, setFilteredAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSpecies, setSelectedSpecies] = useState<string>('all');
  const [selectedSex, setSelectedSex] = useState<string>('all');
  const [selectedAnimal, setSelectedAnimal] = useState<Animal | null>(null);

  const ONG_PHONE = "5500000000000"; 

  useEffect(() => {
    async function fetchAnimals() {
      try {
        const data = await getAnimalsByStatus('available_for_adoption');
        setAnimals(data);
        setFilteredAnimals(data);
      } catch (error) {
        console.error('Error fetching animals:', error);
      } finally {
        setLoading(false);
      }
    }
    fetchAnimals();
  }, []);

  useEffect(() => {
    let filtered = animals;
    if (selectedSpecies !== 'all') {
      filtered = filtered.filter(a => a.species.toLowerCase() === selectedSpecies.toLowerCase());
    }
    if (selectedSex !== 'all') {
      filtered = filtered.filter(a => a.sex.toLowerCase() === selectedSex.toLowerCase());
    }
    setFilteredAnimals(filtered);
  }, [selectedSpecies, selectedSex, animals]);

  const handleAdoptClick = (animal: Animal) => {
    const message = `Olá! Vi o(a) ${animal.name} no site Patinhas e Amor. Ele(a) é um ${animal.species} ${animal.sex} de porte ${animal.size} e gostaria de saber mais sobre a adoção!`;
    const whatsappUrl = `https://wa.me/${ONG_PHONE}?text=${encodeURIComponent(message)}`;
    window.open(whatsappUrl, '_blank');
  };

  // Variantes otimizadas (GPU accelerated)
  const modalVariants: Variants = {
    hidden: { 
      opacity: 0, 
      y: 15,
    },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { 
        duration: 0.25,
        ease: [0.4, 0, 0.2, 1] 
      }
    },
    exit: { 
      opacity: 0, 
      y: 10,
      transition: { duration: 0.15 } 
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <main className="flex-grow py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <FadeIn direction="down">
            <h1 className="text-3xl md:text-4xl font-bold text-gray-800 mb-4">
              🐕 Animais para Adoção
            </h1>
          </FadeIn>
          
          <FadeIn direction="down" delay={0.1}>
            <p className="text-gray-600 mb-8">
              Encontre seu novo melhor amigo! Todos esses animais estão esperando por um lar amoroso.
            </p>
          </FadeIn>

          {/* Filtros */}
          <FadeIn direction="up" delay={0.2}>
            <div className="bg-white p-4 rounded-2xl shadow-sm mb-8 flex flex-wrap gap-4 border border-gray-100">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase ml-1">Espécie</label>
                <select 
                  value={selectedSpecies} 
                  onChange={(e) => setSelectedSpecies(e.target.value)} 
                  className="border border-gray-200 rounded-xl px-4 py-2 bg-gray-50 focus:ring-2 focus:ring-orange-500 outline-none transition-all"
                >
                  <option value="all">Todas as Espécies</option>
                  <option value="cachorro">Cães</option>
                  <option value="gato">Gatos</option>
                </select>
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase ml-1">Sexo</label>
                <select 
                  value={selectedSex} 
                  onChange={(e) => setSelectedSex(e.target.value)} 
                  className="border border-gray-200 rounded-xl px-4 py-2 bg-gray-50 focus:ring-2 focus:ring-orange-500 outline-none transition-all"
                >
                  <option value="all">Todos os Sexos</option>
                  <option value="macho">Macho</option>
                  <option value="fêmea">Fêmea</option>
                </select>
              </div>
            </div>
          </FadeIn>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="h-12 w-12 border-4 border-orange-600 border-t-transparent rounded-full animate-spin mb-4" />
              <p className="text-gray-500 animate-pulse italic">Buscando amiguinhos...</p>
            </div>
          ) : (
            <FadeIn delay={0.2}>
              <AnimalGrid
                animals={filteredAnimals}
                onAnimalClick={(animal) => setSelectedAnimal(animal)}
                onAdoptClick={handleAdoptClick}
                emptyMessage="Nenhum animal encontrado com os filtros selecionados."
              />
            </FadeIn>
          )}
        </div>
      </main>

      <AnimatePresence>
        {selectedAnimal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            {/* Overlay - Sem blur para manter 60 FPS */}
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedAnimal(null)}
              className="absolute inset-0 bg-slate-900/60"
            />

            {/* Modal Card - GPU Accelerated */}
            <motion.div 
              variants={modalVariants}
              initial="hidden"
              animate="visible"
              exit="exit"
              className="relative bg-white w-full max-w-md rounded-[2.5rem] shadow-2xl overflow-hidden transform-gpu will-change-transform"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="relative aspect-square bg-slate-100">
                <img 
                  src={selectedAnimal.imageUrl || ANIMAL_PLACEHOLDER_IMAGE} 
                  alt={selectedAnimal.name} 
                  className="w-full h-full object-cover" 
                />
                <button 
                  onClick={() => setSelectedAnimal(null)}
                  className="absolute top-4 right-4 bg-black/20 hover:bg-black/40 text-white w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-md transition-all z-10"
                >
                  ✕
                </button>
              </div>
              
              <div className="p-6 md:p-8 max-h-[60vh] overflow-y-auto scrollbar-hide">
                <div className="flex justify-between items-start mb-6">
                  <div>
                    <h2 className="text-3xl font-black text-slate-800 uppercase leading-none mb-1">{selectedAnimal.name}</h2>
                    <p className="text-orange-600 font-bold text-sm">
                      {selectedAnimal.species} • {selectedAnimal.sex}
                    </p>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2 mb-8">
                  <div className="bg-slate-50 p-3 rounded-2xl text-center border border-slate-100">
                    <p className="text-[9px] text-slate-400 uppercase font-black tracking-wider">Idade</p>
                    <p className="text-slate-800 font-bold text-xs">{selectedAnimal.age} Anos</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl text-center border border-slate-100">
                    <p className="text-[9px] text-slate-400 uppercase font-black tracking-wider">Porte</p>
                    <p className="text-slate-800 font-bold text-xs">{selectedAnimal.size}</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl text-center border border-slate-100">
                    <p className="text-[9px] text-slate-400 uppercase font-black tracking-wider">Sexo</p>
                    <p className="text-slate-800 font-bold text-xs">{selectedAnimal.sex}</p>
                  </div>
                </div>

                <div className="mb-8">
                  <h4 className="font-black text-slate-400 text-[10px] uppercase tracking-[0.2em] mb-2">Sobre</h4>
                  <p className="text-slate-600 text-sm leading-relaxed italic">
                    "{selectedAnimal.description || "Sem descrição disponível."}"
                  </p>
                </div>

                <motion.button
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleAdoptClick(selectedAnimal)}
                  className="w-full bg-gradient-to-r from-orange-500 to-orange-600 text-white py-4 rounded-2xl font-black text-sm uppercase tracking-widest shadow-xl shadow-orange-100 transition-all"
                >
                  Quero Adotar
                </motion.button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <footer className="bg-slate-900 text-slate-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <span className="text-2xl">🐾</span>
            <span className="text-xl font-bold text-white uppercase tracking-tighter">Patinhas e Amor</span>
          </div>
          <p className="text-[10px] uppercase tracking-widest opacity-60 mt-4 italic">
            © 2026 • Porto União
          </p>
        </div>
      </footer>
    </div>
  );
}