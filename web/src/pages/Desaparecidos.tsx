import { useEffect, useState } from 'react';
import type { Animal } from '../types';
import { getAnimalsByStatus } from '../services/firestore';
import { AnimalGrid } from '../components/AnimalGrid';

export function Desaparecidos() {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);

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
        <div className="bg-red-100 border-l-4 border-red-500 p-4 mb-8 rounded-r-lg">
          <h1 className="text-3xl md:text-4xl font-bold text-red-800 mb-2">
            ⚠️ Animais Desaparecidos
          </h1>
          <p className="text-red-700">
            Esses animais estão desaparecidos e precisam voltar para casa. Se você
            tiver alguma informação, entre em contato pelo telefone disponível no
            card.
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
            emptyMessage="Nenhum animal desaparecido no momento."
          />
        )}
      </div>
    </div>
  );
}
