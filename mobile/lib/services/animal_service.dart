import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patinhas_amor/models/animal.dart';

/// Service class responsible for handling all Firestore communication
/// related to animals rescued by the NGO.
class AnimalService {
  // Referência para a coleção "animals" no Firestore
  final CollectionReference _animalsRef =
      FirebaseFirestore.instance.collection('animals');

  /// Fetches all animals registered in Firestore.
  ///
  /// Returns a list of [Animal] objects.
  /// Throws an exception if the request fails.
  Future<List<Animal>> fetchAnimals() async {
    try {
      // Busca todos os documentos da coleção
      final QuerySnapshot snapshot = await _animalsRef.get();

      // Converte cada documento em um objeto Animal usando o doc.id
      return snapshot.docs.map((doc) {
        return Animal.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load animals from Firestore: $e');
    }
  }

  /// Creates a new animal record in Firestore.
  ///
  /// [animal] is the animal data to be registered.
  /// Returns the created [Animal] with its assigned Firestore ID.
  Future<Animal> createAnimal(Animal animal) async {
    try {
      // O Firestore gera o ID automaticamente (.add)
      // O animal.toJson() já cuida de não enviar o ID no corpo se ele for nulo
      final DocumentReference docRef = await _animalsRef.add(animal.toJson());

      // Busca o documento recém-criado para confirmar os dados e o ID
      final DocumentSnapshot doc = await docRef.get();

      return Animal.fromJson(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
    } catch (e) {
      throw Exception('Failed to create animal in Firestore: $e');
    }
  }

  /// Opcional: Stream para ouvir mudanças em tempo real (Real-time)
  /// Útil se você quiser que a lista atualize sozinha sem refresh
  Stream<List<Animal>> getAnimalsStream() {
    return _animalsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Animal.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    });
  }

  /// No Firestore, não há necessidade de fechar o client como no HTTP,
  /// mas mantemos o método por padrão de estrutura.
  void dispose() {
    // Firestore gerencia o ciclo de vida automaticamente
  }
}