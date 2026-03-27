import { Timestamp } from 'firebase/firestore';

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

export type OccurrenceType = 'Bravos' | 'Perdidos' | 'Maus Tratos' | 'Outros';

export type OccurrenceStatus = 'pending' | 'in_progress' | 'resolved';

export interface Occurrence {
  id?: string;
  type: OccurrenceType;
  location: string;
  description: string;
  status: OccurrenceStatus;
  createdAt: Timestamp;
  reporterPhone: string;
}
