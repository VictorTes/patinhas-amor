import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { Animal } from '../types';
import { getAnimalsByStatus } from '../services/firebaseService';
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

          {/* Filtros com Animação */}
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
              <motion.div 
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
                className="h-12 w-12 border-4 border-orange-600 border-t-transparent rounded-full mb-4"
              />
              <p className="text-gray-500 animate-pulse">Buscando amiguinhos...</p>
            </div>
          ) : (
            <motion.div
              layout
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.5 }}
            >
              <AnimalGrid
                animals={filteredAnimals}
                onAnimalClick={(animal) => setSelectedAnimal(animal)}
                onAdoptClick={handleAdoptClick}
                emptyMessage="Nenhum animal encontrado com os filtros selecionados."
              />
            </motion.div>
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
            className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
            onClick={() => setSelectedAnimal(null)}
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20, opacity: 0 }}
              animate={{ scale: 1, y: 0, opacity: 1 }}
              exit={{ scale: 0.9, y: 20, opacity: 0 }}
              className="bg-white rounded-3xl shadow-2xl max-w-md w-full overflow-hidden"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="relative aspect-square bg-slate-100">
                <img 
                  src={selectedAnimal.imageUrl} 
                  alt={selectedAnimal.name} 
                  className="w-full h-full object-cover" 
                />
                <button 
                  onClick={() => setSelectedAnimal(null)}
                  className="absolute top-4 right-4 bg-black/30 hover:bg-black/50 text-white w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-md transition-colors"
                >
                  ✕
                </button>
              </div>
              
              <div className="p-6">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h2 className="text-3xl font-bold text-slate-800">{selectedAnimal.name}</h2>
                    <p className="text-orange-600 font-medium">
                      {selectedAnimal.species} • {selectedAnimal.sex}
                    </p>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3 mb-6">
                  <div className="bg-slate-50 p-3 rounded-2xl text-center">
                    <p className="text-[10px] text-slate-500 uppercase font-bold">Idade</p>
                    <p className="text-slate-800 font-semibold text-sm">{selectedAnimal.age} Anos</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl text-center">
                    <p className="text-[10px] text-slate-500 uppercase font-bold">Porte</p>
                    <p className="text-slate-800 font-semibold text-sm">{selectedAnimal.size}</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl text-center">
                    <p className="text-[10px] text-slate-500 uppercase font-bold">Sexo</p>
                    <p className="text-slate-800 font-semibold text-sm">{selectedAnimal.sex}</p>
                  </div>
                </div>

                <div className="mb-6">
                  <h4 className="font-bold text-slate-800 mb-1 text-sm uppercase tracking-wide">Sobre</h4>
                  <p className="text-slate-600 text-sm leading-relaxed">{selectedAnimal.description}</p>
                </div>

                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleAdoptClick(selectedAnimal)}
                  className="w-full bg-gradient-to-r from-orange-500 to-orange-600 text-white py-4 rounded-2xl font-bold text-lg shadow-lg hover:shadow-orange-200 transition-all"
                >
                  Quero Adotar o(a) {selectedAnimal.name}
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <footer className="bg-slate-900 text-slate-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <span className="text-2xl">🐾</span>
            <span className="text-xl font-bold text-white">Patinhas e Amor</span>
          </div>
          <p className="text-sm">
            ONG dedicada ao resgate e adoção de animais abandonados.
          </p>
          <p className="text-sm mt-2">© 2026 Patinhas e Amor. Todos os direitos reservados.</p>
        </div>
      </footer>
    </div>
  );
}