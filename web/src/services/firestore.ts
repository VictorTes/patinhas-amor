import { collection, query, where, getDocs, addDoc, orderBy } from 'firebase/firestore';
import { db } from '../config/firebase';
import type { Animal, AnimalStatus, Occurrence } from '../types';

const ANIMALS_COLLECTION = 'animals';
const OCCURRENCES_COLLECTION = 'occurrences';

export async function getAnimalsByStatus(status: AnimalStatus): Promise<Animal[]> {
  const q = query(
    collection(db, ANIMALS_COLLECTION),
    where('status', '==', status),
    orderBy('name')
  );

  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as Animal[];
}

export async function getAllAnimals(): Promise<Animal[]> {
  const querySnapshot = await getDocs(collection(db, ANIMALS_COLLECTION));
  return querySnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as Animal[];
}

export async function createOccurrence(occurrence: Omit<Occurrence, 'id'>): Promise<void> {
  await addDoc(collection(db, OCCURRENCES_COLLECTION), occurrence);
}
