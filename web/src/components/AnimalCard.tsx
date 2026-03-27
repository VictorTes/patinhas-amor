import type { Animal } from '../types';
import { formatRescueDate, ANIMAL_PLACEHOLDER_IMAGE } from '../services/firebaseService';
import { Link } from 'react-router-dom';

interface AnimalCardProps {
  animal: Animal;
  variant?: 'default' | 'urgent';
  onClick?: (animal: Animal) => void;
  showDetails?: boolean;
}

export function AnimalCard({
  animal,
  variant = 'default',
  onClick,
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

        {/* Overlay gradiente na imagem */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      </div>

      {/* Conteúdo */}
      <div className="p-5">
        {/* Nome e sexo */}
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-xl font-bold text-slate-800 group-hover:text-orange-500 transition-colors">
            {animal.name}
          </h3>
          <span className="text-lg" title={animal.sex}>
            {getSexIcon(animal.sex)}
          </span>
        </div>

        {/* Informações rápidas */}
        <div className="flex items-center gap-4 text-sm text-slate-500 mb-3">
          <span className="flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            {animal.currentLocation}
          </span>
          <span className="flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
            {animal.size}
          </span>
        </div>

        {/* Descrição curta */}
        {animal.description && (
          <p className="text-slate-600 text-sm line-clamp-2 mb-4">
            {animal.description}
          </p>
        )}

        {/* Data de resgate (se solicitado) */}
        {showDetails && (
          <div className="pt-3 border-t border-slate-100">
            <p className="text-xs text-slate-400">
              Resgatado em {formatRescueDate(animal.rescueDate)}
            </p>
          </div>
        )}

        {/* Contato para desaparecidos */}
        {isUrgent && animal.adopterPhone && (
          <div className="mt-4 p-3 bg-red-50 rounded-xl">
            <p className="text-red-700 text-sm font-medium">
              📞 Contato: {animal.adopterPhone}
            </p>
          </div>
        )}

        {/* Botão de ação */}
        {!isUrgent && (
          <div className="mt-4 pt-4 border-t border-slate-100" onClick={(e) => e.stopPropagation()}>
            <Link
              to="/adocao"
              className="w-full py-2.5 bg-orange-50 text-orange-600 font-semibold rounded-xl hover:bg-orange-500 hover:text-white transition-all duration-200 flex items-center justify-center gap-2 group/btn"
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
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
