import type { Animal } from '../types';
import { formatRescueDate, ANIMAL_PLACEHOLDER_IMAGE } from '../services/firebaseService';

interface AnimalCardProps {
  animal: Animal;
  variant?: 'default' | 'urgent';
  onClick?: (animal: Animal) => void;
  onAdopt?: (animal: Animal) => void; // Nova prop para o WhatsApp direto
  showDetails?: boolean;
}

export function AnimalCard({
  animal,
  variant = 'default',
  onClick,
  onAdopt,
  showDetails = false,
}: AnimalCardProps) {
  const isUrgent = variant === 'urgent' || animal.status === 'missing';
  const imageUrl = animal.imageUrl || ANIMAL_PLACEHOLDER_IMAGE;

  // Ícones baseados na espécie
  const getSpeciesIcon = (species: string) => {
    const lower = species.toLowerCase();
    if (lower.includes('cão') || lower.includes('dog')) return '🐕';
    if (lower.includes('gato') || lower.includes('cat')) return '🐱';
    return '🐾';
  };

  // Ícone baseado no sexo
  const getSexIcon = (sex: string) => {
    const lower = sex.toLowerCase();
    if (lower.includes('macho')) return '♂️';
    if (lower.includes('fêmea') || lower.includes('femea')) return '♀️';
    return '';
  };

  return (
    <div
      onClick={() => onClick?.(animal)}
      className={`
        group bg-white rounded-2xl overflow-hidden cursor-pointer
        transition-all duration-300 ease-out
        hover:shadow-xl hover:-translate-y-1
        ${isUrgent ? 'ring-2 ring-red-400 shadow-red-100' : 'shadow-sm border border-slate-100'}
      `}
    >
      {/* Imagem */}
      <div className="relative h-56 overflow-hidden">
        <img
          src={imageUrl}
          alt={animal.name}
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          onError={(e) => {
            (e.target as HTMLImageElement).src = ANIMAL_PLACEHOLDER_IMAGE;
          }}
        />

        {/* Badge de status */}
        {isUrgent && (
          <div className="absolute top-3 right-3 bg-red-500 text-white px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide shadow-lg animate-pulse">
            ⚠️ Desaparecido
          </div>
        )}

        {/* Badge de espécie */}
        <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm text-slate-700 px-3 py-1.5 rounded-full text-sm font-medium shadow-sm">
          {getSpeciesIcon(animal.species)} {animal.species}
        </div>
      </div>

      {/* Conteúdo */}
      <div className="p-5">
        {/* Nome e sexo */}
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-xl font-bold text-slate-800 group-hover:text-orange-500 transition-colors">
            {animal.name}
          </h3>
          <span className="text-lg" title={animal.sex}>
            {getSexIcon(animal.sex)}
          </span>
        </div>

        {/* Informações rápidas (Idade, Porte e Sexo) */}
        <div className="grid grid-cols-2 gap-y-2 text-sm text-slate-500 mb-4">
          <span className="flex items-center gap-1">
            <span className="opacity-70">🎂</span> {animal.age} {' '} Anos
          </span>
          <span className="flex items-center gap-1">
            <span className="opacity-70">⚖️</span> {animal.size}
          </span>
          <span className="flex items-center gap-1">
            <span className="opacity-70">✨</span> {animal.sex}
          </span>
        </div>

        {/* Descrição curta (se houver) */}
        {animal.description && (
          <p className="text-slate-600 text-sm line-clamp-2 mb-4 italic">
            "{animal.description}"
          </p>
        )}

        {/* Data de resgate (Opcional) */}
        {showDetails && (
          <div className="pt-3 border-t border-slate-100 mb-4">
            <p className="text-xs text-slate-400">
              Resgatado em {formatRescueDate(animal.rescueDate)}
            </p>
          </div>
        )}

        {/* Botão de ação direta para WhatsApp */}
        {!isUrgent && (
          <div className="mt-2 pt-4 border-t border-slate-50">
            <button
              onClick={(e) => {
                e.stopPropagation(); // Impede de abrir o modal de detalhes
                onAdopt?.(animal);
              }}
              className="w-full py-3 bg-orange-500 text-white font-bold rounded-xl hover:bg-orange-600 shadow-md hover:shadow-orange-200 transition-all duration-200 flex items-center justify-center gap-2 group/btn"
            >
              <span>Quero Adotar</span>
              <svg
                className="w-4 h-4 transition-transform group-hover/btn:translate-x-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </button>
          </div>
        )}

        {/* Contato para casos urgentes */}
        {isUrgent && animal.adopterPhone && (
          <div className="mt-4 p-3 bg-red-50 rounded-xl border border-red-100">
            <p className="text-red-700 text-sm font-bold flex items-center gap-2">
              📞 Contato: {animal.adopterPhone}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}