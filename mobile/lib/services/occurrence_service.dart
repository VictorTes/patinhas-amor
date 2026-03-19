import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patinhas_amor/models/occurrence.dart';

/// Service responsável por gerenciar as ocorrências (denúncias) no Firebase Firestore.
class OccurrenceService {
  // Referência para a coleção 'occurrences' no banco de dados
  final CollectionReference _occurrencesRef =
      FirebaseFirestore.instance.collection('occurrences');

  /// Busca todas as ocorrências em tempo real (Stream).
  /// Ideal para o seu mapa ou lista, pois atualiza a UI automaticamente.
  Stream<List<Occurrence>> getOccurrencesStream() {
    return _occurrencesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Passamos o doc.id para o model para podermos editar/deletar depois
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
      // O método .add() gera um ID automático para o documento
      await _occurrencesRef.add(occurrence.toJson());
    } catch (e) {
      throw Exception('Erro ao registrar ocorrência no Firebase: $e');
    }
  }

  /// Atualiza o status de uma ocorrência (Pendente, Em Andamento, Resolvida).
  /// [id] deve ser a String gerada pelo Firestore.
  Future<void> updateOccurrenceStatus(String id, String status) async {
    try {
      await _occurrencesRef.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(), // Marca o horário da última alteração
      });
    } catch (e) {
      throw Exception('Erro ao atualizar status da ocorrência: $e');
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

  /// No Firestore, não é necessário o dispose() do cliente HTTP, 
  /// mas mantemos a assinatura caso você use controllers de stream futuramente.
  void dispose() {
    // Implementar se usar StreamControllers personalizados
  }
}