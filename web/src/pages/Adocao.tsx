import { useEffect, useState } from 'react';
import type { Animal } from '../types';
import { getAnimalsByStatus } from '../services/firestore';
import { AnimalGrid } from '../components/AnimalGrid';

export function Adocao() {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [filteredAnimals, setFilteredAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSpecies, setSelectedSpecies] = useState<string>('all');
  const [selectedSex, setSelectedSex] = useState<string>('all');

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
      filtered = filtered.filter(
        (animal) => animal.species.toLowerCase() === selectedSpecies.toLowerCase()
      );
    }

    if (selectedSex !== 'all') {
      filtered = filtered.filter(
        (animal) => animal.sex.toLowerCase() === selectedSex.toLowerCase()
      );
    }

    setFilteredAnimals(filtered);
  }, [selectedSpecies, selectedSex, animals]);

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl md:text-4xl font-bold text-gray-800 mb-4">
          🐕 Animais para Adoção
        </h1>
        <p className="text-gray-600 mb-8">
          Encontre seu novo melhor amigo! Todos esses animais estão esperando por um lar amoroso.
        </p>

        {/* Filters */}
        <div className="bg-white p-4 rounded-lg shadow-sm mb-8 flex flex-wrap gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Espécie
            </label>
            <select
              value={selectedSpecies}
              onChange={(e) => setSelectedSpecies(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="all">Todas</option>
              <option value="cão">Cão</option>
              <option value="gato">Gato</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sexo
            </label>
            <select
              value={selectedSex}
              onChange={(e) => setSelectedSex(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="all">Todos</option>
              <option value="macho">Macho</option>
              <option value="fêmea">Fêmea</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
          </div>
        ) : (
          <AnimalGrid
            animals={filteredAnimals}
            emptyMessage="Nenhum animal encontrado com os filtros selecionados."
          />
        )}
      </div>
    </div>
  );
}
