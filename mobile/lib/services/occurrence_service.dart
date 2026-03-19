import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patinhas_amor/models/occurrence.dart';

/// Service responsável por gerenciar as ocorrências (denúncias) no Firebase Firestore.
class OccurrenceService {
  // Referência para a coleção 'occurrences' no banco de dados
  final CollectionReference _occurrencesRef =
      FirebaseFirestore.instance.collection('occurrences');

  /// Busca todas as ocorrências em tempo real (Stream).
  Stream<List<Occurrence>> getOccurrencesStream() {
    return _occurrencesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Occurrence.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    });
  }

  /// Cria uma nova ocorrência (denúncia) no Firestore.
  Future<void> createOccurrence(Occurrence occurrence) async {
    try {
      await _occurrencesRef.add(occurrence.toJson());
    } catch (e) {
      throw Exception('Erro ao registrar ocorrência no Firebase: $e');
    }
  }

  /// Atualiza o status e/ou a observação/resolução da ocorrência.
  /// 
  /// [id] é o identificador do documento no Firestore.
  /// [status] é o novo status (pending, in_progress, resolved).
  /// [resolutionDescription] é a nota de observação ou relato da resolução.
  Future<void> updateOccurrenceStatus(
    String id, 
    String status, 
    {String? resolutionDescription}
  ) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        // O Firestore atualizará o campo com o novo texto ou com null se estiver vazio.
        'resolutionDescription': resolutionDescription,
      };

      await _occurrencesRef.doc(id).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar dados da ocorrência: $e');
    }
  }

  /// Deleta uma ocorrência do banco de dados.
  Future<void> deleteOccurrence(String id) async {
    try {
      await _occurrencesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao remover ocorrência: $e');
    }
  }

  /// Busca uma única ocorrência pelo ID (útil para Deep Links ou notificações).
  Future<Occurrence?> getOccurrenceById(String id) async {
    try {
      final doc = await _occurrencesRef.doc(id).get();
      if (doc.exists) {
        return Occurrence.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar ocorrência específica: $e');
    }
  }

  void dispose() {
    // Implementar se usar StreamControllers personalizados no futuro
  }
}