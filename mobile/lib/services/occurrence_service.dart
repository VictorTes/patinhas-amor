import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:patinhas_amor/models/occurrence.dart';

class OccurrenceService {
  final CollectionReference _occurrencesRef =
      FirebaseFirestore.instance.collection('occurrences');

  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'padrão');

  // ==========================================
  // FUNÇÃO DE FILTRAGEM (WEB APROVADA + APP)
  // ==========================================
  /// Aplica a regra: 
  /// 1. Se tiver o campo 'status' (vinda da web), deve ser 'approved'.
  /// 2. Se NÃO tiver o campo 'status' (vinda do app), deve aparecer sempre.
  List<Occurrence> _filterWebAndApp(QuerySnapshot snapshot) {
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Se o campo 'status' não existe, é vinda do App (voluntário) -> Permitir
      if (!data.containsKey('status')) {
        return true;
      }
      
      // Se o campo 'status' existe, só permitir se for 'approved' (vinda da Web)
      return data['status'] == 'approved';
    }).map((doc) {
      return Occurrence.fromJson(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
    }).toList();
  }

  /// Busca para relatórios (estático)
  Future<List<Occurrence>> fetchOccurrences() async {
    try {
      final querySnapshot = await _occurrencesRef
          .orderBy('createdAt', descending: true)
          .get();

      return _filterWebAndApp(querySnapshot);
    } catch (e) {
      throw Exception('Erro ao carregar dados para relatório: $e');
    }
  }

  /// Stream em tempo real para a listagem principal
  Stream<List<Occurrence>> getOccurrencesStream() {
    return _occurrencesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => _filterWebAndApp(snapshot));
  }

  // --- MÉTODOS DE UPLOAD E PERSISTÊNCIA ---

  Future<String?> uploadOccurrenceImage(File imageFile) async {
    if (_cloudName.isEmpty) return null;
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'ocorrencias'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonRes = jsonDecode(responseString);
        return jsonRes['secure_url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createOccurrence(Occurrence occurrence) async {
    try {
      final data = occurrence.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (data['createdAt'] == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      // Note: Não adicionamos o campo 'status' aqui para manter a distinção App vs Web
      await _occurrencesRef.add(data);
    } catch (e) {
      throw Exception('Erro ao registrar ocorrência: $e');
    }
  }

  Future<void> updateOccurrence(Occurrence occurrence) async {
    try {
      if (occurrence.id == null) return;
      final data = occurrence.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _occurrencesRef.doc(occurrence.id).update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar ocorrência: $e');
    }
  }

  Future<void> updateOccurrenceStatus(
    String id, 
    OccurrenceStatus status, 
    {String? resolutionDescription}
  ) async {
    try {
      final Map<String, dynamic> updateData = {
        // 'status' aqui refere-se ao status de resolução do animal (pendente/resolvido)
        // conforme sua lógica anterior.
        'situation': status.value, 
        'updatedAt': FieldValue.serverTimestamp(),
        'resolutionDescription': resolutionDescription,
      };
      await _occurrencesRef.doc(id).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  Future<void> deleteOccurrence(String id) async {
    try {
      await _occurrencesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao remover ocorrência: $e');
    }
  }

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
      throw Exception('Erro ao buscar ocorrência: $e');
    }
  }
}