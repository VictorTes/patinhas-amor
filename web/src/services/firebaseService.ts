import {
  collection,
  query,
  where,
  getDocs,
  addDoc,
  orderBy,
  Timestamp,
  serverTimestamp,
  type DocumentData,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import type { Animal, AnimalStatus, Occurrence } from '../types';

// Alterado para a coleção principal que o App consome
const ANIMALS_COLLECTION = 'animals';
const OCCURRENCES_COLLECTION = 'occurrences'; 
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

export async function uploadOccurrenceImage(file: File): Promise<string> {
  try {
    if (file.size > MAX_FILE_SIZE) {
      throw new Error(`Arquivo muito grande. Máximo permitido: 2MB`);
    }

    const cloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', uploadPreset);
    formData.append('folder', 'ocorrencias_web');

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      { method: 'POST', body: formData }
    );

    if (!response.ok) throw new Error('Falha no upload para o Cloudinary');
    const data = await response.json();
    return data.secure_url;
  } catch (error) {
    console.error('[Cloudinary] Erro no upload:', error);
    throw error;
  }
}

// --- FUNÇÕES DE CRIAÇÃO (OCORRÊNCIAS) ---

/**
 * Cria a ocorrência na coleção principal com status_web pendente.
 */
export async function createPendingOccurrence(formData: OccurrenceFormData): Promise<void> {
  try {
    const secureData = {
      // Identificadores de Moderação Web
      status_web: 'pending', // Campo que o App usará para filtrar
      
      // Dados da Ocorrência
      reporterName: formData.reporterName.trim(),
      reporterPhone: formData.reporterPhone.trim(),
      imageUrl: formData.imageUrl,
      
      // Status de resolução do animal (compatível com o App)
      status: 'pending', 
      
      type: formData.type || 'Não especificado',
      location: formData.location.trim() || 'Não informada',
      description: formData.description.trim() || '',
      latitude: formData.latitude ?? null,
      longitude: formData.longitude ?? null,
      
      // Timestamps
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      
      // Metadados
      userAgent: navigator.userAgent,
      source: 'web' // Tag extra para facilitar buscas futuras
    };

    // Salvando na mesma coleção que o App lê ('occurrences')
    await addDoc(collection(db, OCCURRENCES_COLLECTION), secureData);
    console.log('[Firebase] Ocorrência Web registrada para moderação!');
  } catch (error) {
    console.error('[Firebase] Erro ao criar ocorrência:', error);
    throw error;
  }
}

/**
 * Mantida para compatibilidade
 */
export async function createOccurrence(occurrence: Omit<Occurrence, 'id'>): Promise<void> {
  return createPendingOccurrence({
    reporterName: "Usuário Web",
    reporterPhone: occurrence.reporterPhone || '',
    type: occurrence.type,
    location: occurrence.location,
    description: occurrence.description,
    imageUrl: '',
    latitude: occurrence.latitude,
    longitude: occurrence.longitude
  });
}

// --- HELPERS DE FORMATAÇÃO ---

export function formatRescueDate(timestamp: any): string {
  if (!timestamp) return 'Data não informada';
  try {
    const date = timestamp instanceof Timestamp ? timestamp.toDate() : new Date(timestamp);
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

export const ANIMAL_PLACEHOLDER_IMAGE = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&h=300&fit=crop';