import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pending_occurrence.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _pendingCollection = 'pending_occurrences';
  final String _finalCollection = 'occurrences'; // Coleção principal do App

  /// Recupera as ocorrências pendentes da Web em tempo real.
  Stream<List<PendingOccurrence>> getPendingOccurrences() {
    return _db
        .collection(_pendingCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PendingOccurrence.fromFirestore(doc))
            .toList());
  }

  /// APROVAR: Migra os dados para a coleção 'occurrences' e remove de 'pending_occurrences'
  Future<void> approveOccurrence(String docId, Map<String, dynamic> updatedData, PendingOccurrence originalData) async {
    try {
      // Usamos um Batch para garantir que ou as duas ações acontecem, ou nenhuma.
      WriteBatch batch = _db.batch();

      // 1. Referência para o novo documento na coleção final
      // Dica: Você pode usar .doc() para gerar um ID novo ou .doc(docId) para manter o mesmo ID
      DocumentReference finalDocRef = _db.collection(_finalCollection).doc();

      // 2. Preparar os dados para a coleção principal
      // Mesclamos os dados originais com as edições feitas na moderação
      Map<String, dynamic> dataToMigrate = {
        'reporterName': originalData.reporterName,
        'reporterPhone': originalData.reporterPhone,
        'imageUrl': originalData.imageUrl,
        'type': updatedData['type'] ?? originalData.type,
        'location': updatedData['location'] ?? originalData.location,
        'description': updatedData['description'] ?? originalData.description,
        'latitude': originalData.latitude,
        'longitude': originalData.longitude,
        // Campos de controle
        'status': 'pending', // No app, ela entra como pendente de RESOLUÇÃO, mas visível
        'status_web': 'approved',
        'isValidated': true,
        'createdAt': originalData.createdAt,
        'approvedAt': FieldValue.serverTimestamp(),
      };

      // Adicionar criação ao batch
      batch.set(finalDocRef, dataToMigrate);

      // 3. Deletar da coleção de pendentes (limpando a triagem)
      DocumentReference pendingDocRef = _db.collection(_pendingCollection).doc(docId);
      batch.delete(pendingDocRef);

      // Commit das operações
      await batch.commit();
    } catch (e) {
      throw Exception("Erro ao aprovar e migrar ocorrência: $e");
    }
  }

  /// RECUSAR: Apenas marca como rejeitada na coleção de triagem
  Future<void> rejectOccurrence(String docId) async {
    try {
      await _db.collection(_pendingCollection).doc(docId).update({
        'status': 'rejected',
        'isValidated': false,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erro ao recusar ocorrência: $e");
    }
  }

  /// EXCLUIR: Remove permanentemente da triagem
  Future<void> deleteOccurrence(String docId) async {
    try {
      await _db.collection(_pendingCollection).doc(docId).delete();
    } catch (e) {
      throw Exception("Erro ao excluir permanentemente: $e");
    }
  }
}