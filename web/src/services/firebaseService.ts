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

// Coleções
const ANIMALS_COLLECTION = 'animals';
const OCCURRENCES_COLLECTION = 'occurrences'; // Alterado para bater com a coleção que o App consome
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

/**
 * Valida se o arquivo está dentro do limite de tamanho
 */
export function validateFileSize(file: File): boolean {
  return file.size <= MAX_FILE_SIZE;
}

/**
 * Formata o tamanho do arquivo para exibição legível
 */
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

/**
 * Cria a ocorrência com os campos necessários para o App e Moderação
 */
export async function createPendingOccurrence(formData: OccurrenceFormData): Promise<void> {
  try {
    const secureData = {
      // Dados do Relator
      reporterName: formData.reporterName.trim(),
      reporterPhone: formData.reporterPhone.trim(),
      
      // Dados da Ocorrência
      type: formData.type || 'Não especificado',
      location: formData.location.trim() || 'Não informada',
      description: formData.description.trim() || '',
      imageUrl: formData.imageUrl || '',
      latitude: formData.latitude ?? null,
      longitude: formData.longitude ?? null,
      
      // Controle de Moderação e Status
      status: 'pending',     // Status para o fluxo do App
      status_web: 'pending', // Tag específica para moderação web
      isValidated: false,    // Controle de segurança
      
      // Metadados e Timestamps
      createdAt: serverTimestamp(),
      submittedAt: new Date().toISOString(),
      userAgent: navigator.userAgent,
      source: 'web'
    };

    // Salvando na coleção 'occurrences' para visibilidade imediata (ou conforme sua lógica de moderação)
    await addDoc(collection(db, OCCURRENCES_COLLECTION), secureData);
    console.log('[Firebase] Ocorrência registrada com sucesso!');
  } catch (error) {
    console.error('[Firebase] Erro ao criar ocorrência:', error);
    throw error;
  }
}

/**
 * Mantida para compatibilidade com implementações antigas
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

export const ANIMAL_PLACEHOLDER_IMAGE = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&h=300&fit=crop';