import type { Animal } from '../types';
import { AnimalCard } from './AnimalCard';

interface AnimalGridProps {
  animals: Animal[];
  variant?: 'default' | 'urgent';
  onAnimalClick?: (animal: Animal) => void; // Abre o Modal
  onAdoptClick?: (animal: Animal) => void;  // Vai direto pro Whats
  emptyMessage?: string;
  columns?: 2 | 3 | 4;
}

export function AnimalGrid({
  animals,
  variant = 'default',
  onAnimalClick,
  onAdoptClick,
  emptyMessage = 'Nenhum animal encontrado.',
  columns = 4,
}: AnimalGridProps) {
  const gridCols = {
    2: 'grid-cols-1 sm:grid-cols-2',
    3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
    4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4',
  };

  if (animals.length === 0) {
    return (
      <div className="text-center py-16 px-4">
        <div className="w-24 h-24 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <span className="text-4xl">🐾</span>
        </div>
        <p className="text-slate-500 text-lg font-medium mb-2">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className={`grid ${gridCols[columns]} gap-6 lg:gap-8`}>
      {animals.map((animal) => (
        <AnimalCard
          key={animal.id}
          animal={animal}
          variant={variant}
          onClick={onAnimalClick}
          onAdopt={onAdoptClick} // Nova prop
        />
      ))}
    </div>
  );
}