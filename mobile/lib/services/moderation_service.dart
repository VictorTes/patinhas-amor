import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pending_occurrence.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'pending_occurrences';

  /// Recupera as ocorrências pendentes em tempo real.
  /// Usamos snapshots para que a lista no app atualize sozinha quando 
  /// uma nova ocorrência for enviada pelo site ou por outro usuário.
  Stream<List<PendingOccurrence>> getPendingOccurrences() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        // Importante: Para usar o orderBy com o where, você pode precisar 
        // criar um índice no console do Firebase se ele solicitar no log.
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PendingOccurrence.fromFirestore(doc))
            .toList());
  }

  /// Aprova uma ocorrência.
  /// Recebe os dados editados (descrição e localização) para salvar a versão final.
  Future<void> approveOccurrence(String docId, Map<String, dynamic> updatedData) async {
    try {
      await _db.collection(_collection).doc(docId).update({
        'description': updatedData['description'],
        'location': updatedData['location'],
        'status': 'approved',
        'isValidated': true,
        'validatedAt': FieldValue.serverTimestamp(), // Auditabilidade
      });
    } catch (e) {
      throw Exception("Erro ao aprovar ocorrência: $e");
    }
  }

  /// Recusa uma ocorrência.
  /// A ocorrência permanece no banco com status 'rejected' para histórico,
  /// mas para de aparecer na lista de pendentes e no mapa público.
  Future<void> rejectOccurrence(String docId) async {
    try {
      await _db.collection(_collection).doc(docId).update({
        'status': 'rejected',
        'isValidated': false,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erro ao recusar ocorrência: $e");
    }
  }

  /// Opcional: Deletar definitivamente (se você não quiser manter histórico de lixo)
  Future<void> deleteOccurrence(String docId) async {
    try {
      await _db.collection(_collection).doc(docId).delete();
    } catch (e) {
      throw Exception("Erro ao excluir permanentemente: $e");
    }
  }
}