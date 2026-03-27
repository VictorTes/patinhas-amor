import { Timestamp } from 'firebase/firestore';

// --- TIPOS DE ANIMAIS ---

export type AnimalStatus =
  | 'under_treatment'
  | 'available_for_adoption'
  | 'adopted'
  | 'missing';

export type AnimalSize = 'Pequeno' | 'Médio' | 'Grande';

export type AnimalSex = 'Macho' | 'Fêmea';

export interface Animal {
  id?: string;
  name: string;
  species: string;
  status: AnimalStatus;
  description: string;
  imageUrl: string;
  rescueDate: Timestamp;
  currentLocation: string;
  sex: AnimalSex;
  size: AnimalSize;
  adopterName?: string;
  adopterPhone?: string;
}

// --- TIPOS DE OCORRÊNCIAS ---

export type OccurrenceType = 'Bravos' | 'Perdidos' | 'Maus Tratos' | 'Outros';

export type OccurrenceStatus = 'pending' | 'in_progress' | 'resolved';

export interface Occurrence {
  id?: string;
  type: OccurrenceType;
  location: string;
  description: string;
  status: OccurrenceStatus;
  createdAt: Timestamp | any; // 'any' ajuda com serverTimestamp() do Firebase
  reporterPhone: string;
  reporterName?: string; // Adicionado para o novo formulário
  // NOVOS CAMPOS PARA O MAPA:
  latitude?: number;
  longitude?: number;
  imageUrl?: string;    // Adicionado para suportar fotos nas ocorrências
}