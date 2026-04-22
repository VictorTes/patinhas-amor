import {
  collection,
  query,
  where,
  getDocs,
  addDoc,
  orderBy,
  Timestamp,
  serverTimestamp,
  onSnapshot,
  type DocumentData,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import type { 
  Animal, 
  AnimalStatus, 
  Occurrence, 
  CampaignModel
} from '../types';

// Coleções
const ANIMALS_COLLECTION = 'animals';
const OCCURRENCES_COLLECTION = 'pending_occurrences';
const CAMPAIGNS_COLLECTION = 'campaigns'; // Coleção sincronizada com App Flutter
const MAX_FILE_SIZE = 2 * 1024 * 1024; // 2MB

/**
 * Interface para os dados vindos dos formulários Web
 */
export interface OccurrenceFormData {
  reporterName: string;
  reporterPhone: string;
  type: string;
  location: string;
  description: string;
  imageUrl: string;
  latitude?: number;
  longitude?: number;
  accessCode: string; 
  status: string;
}

// --- FUNÇÕES DE BUSCA (CAMPANHAS) ---

/**
 * Escuta as campanhas em tempo real (Stream)
 * Essencial para refletir mudanças de status feitas no App imediatamente na Web
 */
export function getCampaignsStream(callback: (campaigns: CampaignModel[]) => void) {
  try {
    const q = query(
      collection(db, CAMPAIGNS_COLLECTION),
      orderBy('status', 'asc'), // Ativas costumam vir antes de Finalizadas no enum/string
      orderBy('title', 'asc')
    );

    return onSnapshot(q, (snapshot) => {
      const campaigns = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          // Mapeia receiptUrls do Firestore para a propriedade receipts do Model
          receipts: data.receiptUrls || [],
          // Mapeia a imagem da premiação (adicionado para suportar fotos de cestas, kits, etc)
          prizeImageUrl: data.prizeImageUrl || null,
          // Garante que expenses e prestação de contas sejam incluídos
          expenses: data.expenses || [],
          hasAccountability: data.hasAccountability || false,
          totalCollected: data.totalCollected || 0,
        };
      }) as CampaignModel[];
      callback(campaigns);
    });
  } catch (error) {
    console.error('[Firebase] Erro ao abrir stream de campanhas:', error);
    throw error;
  }
}

// --- FUNÇÕES DE BUSCA (ANIMAIS) ---

function parseAnimalDoc(doc: { id: string; data: () => DocumentData }): Animal {
  const data = doc.data();
  return {
    id: doc.id,
    name: data.name || 'Sem nome',
    species: data.species || 'Não informado',
    status: data.status || 'under_treatment',
    description: data.description || '',
    imageUrl: data.imageUrl || '',
    rescueDate: data.rescueDate || Timestamp.now(),
    currentLocation: data.currentLocation || 'Não informado',
    sex: data.sex || 'Não informado',
    size: data.size || 'Médio',
    adopterName: data.adopterName,
    adopterPhone: data.adopterPhone,
    age: data.age,
  } as Animal;
}

export async function getAnimalsByStatus(status: AnimalStatus): Promise<Animal[]> {
  try {
    const q = query(
      collection(db, ANIMALS_COLLECTION),
      where('status', '==', status),
      orderBy('name', 'asc')
    );
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map((doc) => parseAnimalDoc(doc));
  } catch (error) {
    console.error('[Firebase] Erro ao buscar animais por status:', error);
    return [];
  }
}

export async function getAllAnimals(): Promise<Animal[]> {
  try {
    const querySnapshot = await getDocs(collection(db, ANIMALS_COLLECTION));
    return querySnapshot.docs.map((doc) => parseAnimalDoc(doc));
  } catch (error) {
    console.error('[Firebase] Erro ao buscar todos os animais:', error);
    return [];
  }
}

// --- FUNÇÕES DE APOIO E UPLOAD (CLOUDINARY) ---

export function validateFileSize(file: File): boolean {
  return file.size <= MAX_FILE_SIZE;
}

export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

export async function uploadOccurrenceImage(file: File): Promise<string> {
  try {
    if (!validateFileSize(file)) {
      throw new Error(`Arquivo muito grande. Máximo permitido: 2MB`);
    }

    const cloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      throw new Error('Configuração do Cloudinary ausente no .env');
    }

    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', uploadPreset);
    formData.append('folder', 'ocorrencias_web');

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      { method: 'POST', body: formData }
    );

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error?.message || 'Falha no upload para o Cloudinary');
    }

    const data = await response.json();
    return data.secure_url;
  } catch (error) {
    console.error('[Cloudinary] Erro no upload:', error);
    throw error;
  }
}

// --- FUNÇÕES DE CRIAÇÃO (OCORRÊNCIAS) ---

export async function createPendingOccurrence(formData: OccurrenceFormData): Promise<string> {
  try {
    const secureData = {
      reporterName: formData.reporterName.trim() || 'Anônimo',
      reporterPhone: unmaskPhone(formData.reporterPhone),
      type: formData.type || 'Não especificado',
      location: formData.location.trim() || 'Não informada',
      description: formData.description.trim() || '',
      imageUrl: formData.imageUrl || '',
      latitude: formData.latitude ?? 0,
      longitude: formData.longitude ?? 0,
      accessCode: String(formData.accessCode),
      status: 'pending',     
      status_web: 'pending', 
      isValidated: false,    
      createdAt: serverTimestamp(),
      submittedAt: new Date().toISOString(),
      userAgent: navigator.userAgent,
      source: 'web'
    };

    const docRef = await addDoc(collection(db, OCCURRENCES_COLLECTION), secureData);
    return docRef.id; 
  } catch (error) {
    console.error('[Firebase] Erro ao criar ocorrência:', error);
    throw error;
  }
}

export async function createOccurrence(occurrence: Omit<Occurrence, 'id'>): Promise<void> {
  await createPendingOccurrence({
    reporterName: "Usuário Web",
    reporterPhone: occurrence.reporterPhone || '',
    type: occurrence.type,
    location: occurrence.location,
    description: occurrence.description,
    imageUrl: '',
    latitude: occurrence.latitude,
    longitude: occurrence.longitude,
    accessCode: Math.floor(100000 + Math.random() * 900000).toString(),
    status: 'pending'
  });
}

// --- HELPERS DE FORMATAÇÃO ---

export function formatRescueDate(timestamp: Timestamp | Date | null | undefined): string {
  if (!timestamp) return 'Data não informada';
  try {
    const date = timestamp instanceof Timestamp ? timestamp.toDate() : timestamp;
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' });
  } catch { return 'Data não informada'; }
}

export function formatPhoneNumber(value: string): string {
  const digits = value.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 2) return digits.length ? `(${digits}` : '';
  if (digits.length <= 6) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`;
  if (digits.length <= 10) return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`;
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`;
}

export function unmaskPhone(value: string): string {
  return value.replace(/\D/g, '');
}

export async function getCampaignsOnce(): Promise<CampaignModel[]> {
  try {
    const q = query(
      collection(db, CAMPAIGNS_COLLECTION),
      orderBy('status', 'asc'),
      orderBy('title', 'asc')
    );
    
    const querySnapshot = await getDocs(q);
    
    return querySnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        receipts: data.receiptUrls || [],
        prizeImageUrl: data.prizeImageUrl || null,
        expenses: data.expenses || [],
        hasAccountability: data.hasAccountability || false,
        totalCollected: data.totalCollected || 0,
      } as CampaignModel;
    });
  } catch (error) {
    console.error('[Firebase] Erro ao buscar campanhas:', error);
    return [];
  }
}

export const ANIMAL_PLACEHOLDER_IMAGE = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&h=300&fit=crop';