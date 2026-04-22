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
  age: string;
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
  createdAt: Timestamp | any; 
  reporterPhone: string;
  reporterName?: string;
  latitude?: number;
  longitude?: number;
  imageUrl?: string;
}

// --- TIPOS DE CAMPANHAS ---

export const CampaignType = {
  rifa: 'rifa',
  bazar: 'bazar',
  ajuda: 'ajuda', // Adicionado para cobrir casos gerais de doação
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
  // Campos de recibos sincronizados:
  receiptUrls?: string[]; // Nome exato como está no Firestore
  receipts?: string[];    // Nome usado no front-end/mapeamento
  createdAt?: Timestamp | any;
}