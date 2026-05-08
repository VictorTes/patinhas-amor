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

// Ajustado para refletir o valor exato salvo no Firebase ("Outro")
export const CampaignType = {
  rifa: 'rifa',
  outro: 'Outro'
} as const;

export type CampaignType = typeof CampaignType[keyof typeof CampaignType] | string;

export const CampaignStatus = {
  ativa: 'Ativa',
  cancelada: 'cancelada',
  finalizada: 'concluida' // ou 'Concluída'
} as const;

export type CampaignStatus = typeof CampaignStatus[keyof typeof CampaignStatus] | string;

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
  
  // Valores financeiros
  currentValue?: number;
  goalValue?: number;
  ticketValue?: number;
  totalCollected?: number; // Usado agora como fonte primária
  
  // Dados específicos Rifa / Outros
  drawDate?: string | null;
  eventDateTime?: string | null;
  winner?: string | null;
  address?: string | null;
  
  // Premiação
  prize?: string | null;
  prizeImageUrl?: string | null; 
  
  itemsForSale?: string;
  
  // Prestação de Contas
  hasAccountability: boolean;
  expenses?: ExpenseItem[];
  
  // Campos de recibos sincronizados:
  receiptUrls?: string[] | null; 
  receipts?: string[] | null;    
  createdAt?: Timestamp | any;
}