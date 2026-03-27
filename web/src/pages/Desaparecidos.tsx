import { useEffect, useState } from 'react';
import type { Animal } from '../types';
import { getAnimalsByStatus, ANIMAL_PLACEHOLDER_IMAGE } from '../services/firebaseService';
import { AnimalGrid } from '../components/AnimalGrid';
import { formatPhoneNumber } from '../utils/formatPhoneNumber'


export function Desaparecidos() {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Estado para controlar qual animal está sendo visualizado no Modal
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
    <div className="min-h-screen bg-red-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white border-l-4 border-red-500 p-6 mb-8 rounded-r-2xl shadow-sm">
          <h1 className="text-3xl md:text-4xl font-bold text-red-900 mb-2 flex items-center gap-3">
            <span className="animate-pulse">⚠️</span> Animais Desaparecidos
          </h1>
          <p className="text-red-700 text-lg">
            Esses animais estão longe de casa. Se você tiver **qualquer** informação, 
            por favor, entre em contato pelo telefone disponível no card ou nos detalhes.
          </p>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600 mx-auto"></div>
          </div>
        ) : (
          <AnimalGrid
            animals={animals}
            variant="urgent"
            onAnimalClick={(animal) => setSelectedAnimal(animal)}
            emptyMessage="Nenhum animal desaparecido cadastrado no momento."
          />
        )}
      </div>

      {/* MODAL DE DETALHES */}
      {selectedAnimal && (
        <div 
          className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200"
          onClick={() => setSelectedAnimal(null)}
        >
          <div 
            className="bg-white rounded-3xl shadow-2xl max-w-md w-full overflow-hidden animate-in zoom-in-95 duration-300"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Área da Imagem - Proporção Quadrada (1:1) */}
            <div className="relative aspect-square bg-slate-100 overflow-hidden">
              <img 
                src={selectedAnimal.imageUrl || ANIMAL_PLACEHOLDER_IMAGE} 
                alt={selectedAnimal.name} 
                className="w-full h-full object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = ANIMAL_PLACEHOLDER_IMAGE;
                }}
              />
              
              {/* Botão Fechar */}
              <button 
                onClick={() => setSelectedAnimal(null)}
                className="absolute top-4 right-4 bg-black/30 hover:bg-black/50 text-white w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-md transition-all group z-10"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>

              <div className="absolute bottom-4 left-4 bg-red-600 text-white px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider shadow-lg flex items-center gap-2">
                <span className="animate-ping w-2 h-2 bg-white rounded-full"></span> DESAPARECIDO
              </div>
            </div>
            
            {/* Área de Conteúdo */}
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h2 className="text-2xl font-bold text-slate-900 tracking-tight">{selectedAnimal.name}</h2>
                  <p className="text-red-600 font-medium flex items-center gap-2 text-sm">
                    {selectedAnimal.species} • {selectedAnimal.sex} {selectedAnimal.sex.toLowerCase().includes('macho') ? '♂️' : '♀️'}
                  </p>
                </div>
                <div className="bg-slate-50 px-2 py-1 rounded-lg text-slate-600 text-xs font-semibold border border-slate-100">
                  Porte {selectedAnimal.size}
                </div>
              </div>

              {/* Informações */}
              <div className="mb-5">
                <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2 text-xs uppercase tracking-wide">
                  <svg className="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Detalhes
                </h4>
                <div className="bg-red-50/50 p-4 rounded-xl border border-red-100 text-slate-700 italic text-sm leading-relaxed">
                  {selectedAnimal.description || "Sem informações adicionais."}
                </div>
              </div>

              {/* CONTATO */}
              {selectedAnimal.adopterPhone && (
                <div className="bg-white p-4 rounded-2xl border-2 border-dashed border-red-200 flex flex-col gap-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center text-red-600 text-lg shadow-inner">
                      📞
                    </div>
                    <div>
                      <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">Contato do tutor:</p>
                      <p className="text-lg font-bold text-slate-800 tracking-tight">{formatPhoneNumber(selectedAnimal.adopterPhone)}</p>
                    </div>
                  </div>
                  
                  <a 
                    href={`tel:${selectedAnimal.adopterPhone.replace(/\D/g, '')}`} 
                    className="w-full py-3 bg-red-600 text-white font-bold rounded-xl hover:bg-red-700 transition-all text-center shadow-md active:scale-95 text-sm"
                  >
                    Ligar para Informar
                  </a>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}