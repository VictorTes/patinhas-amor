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
  age: String;
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

// src/types/index.ts

// Usamos objetos constantes em vez de enums para compatibilidade
export const CampaignType = {
  rifa: 'rifa',
  bazar: 'bazar',
  outro: 'outro'
} as const;

export type CampaignType = typeof CampaignType[keyof typeof CampaignType];

export const CampaignStatus = {
  ativa: 'ativa',
  pausada: 'pausada',
  finalizada: 'finalizada'
} as const;

export type CampaignStatus = typeof CampaignStatus[keyof typeof CampaignStatus];

export interface ExpenseItem {
  description: string;
  value: number;
}

export interface CampaignModel {
  id?: string;
  title: string;
  description: string;
  type: CampaignType;
  status: CampaignStatus;
  imageUrl?: string;
  currentValue?: number;
  goalValue?: number;
  ticketValue?: number;
  prize?: string;
  address?: string;
  itemsForSale?: string;
  hasAccountability: boolean;
  totalCollected?: number;
  expenses?: ExpenseItem[];
  receiptUrls?: string[];
}