import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:patinhas_amor/models/occurrence.dart';

/// Service responsável por gerenciar as ocorrências (denúncias) no Firebase e Cloudinary.
class OccurrenceService {
  final CollectionReference _occurrencesRef =
      FirebaseFirestore.instance.collection('occurrences');

  // --- CONFIGURAÇÃO CLOUDINARY VIA DOTENV ---
  // Buscamos as chaves do arquivo .env para manter o padrão do AnimalService
  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'padrão');

  /// Realiza o upload da imagem para o Cloudinary na pasta 'ocorrencias'.
  Future<String?> uploadOccurrenceImage(File imageFile) async {
    if (_cloudName.isEmpty) {
      print('Erro: CLOUDINARY_CLOUD_NAME não encontrado no arquivo .env');
      return null;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'ocorrencias' // <--- SEPARAÇÃO EM PASTA AQUI
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonRes = jsonDecode(responseString);
        return jsonRes['secure_url'] as String;
      } else {
        final errorData = await response.stream.bytesToString();
        print("Erro no upload Cloudinary: ${response.statusCode} - $errorData");
        return null;
      }
    } catch (e) {
      print("Exceção no upload Cloudinary: $e");
      return null;
    }
  }

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

  /// Cria uma nova ocorrência no Firestore.
  Future<void> createOccurrence(Occurrence occurrence) async {
    try {
      final data = occurrence.toJson();
      // Garantimos que o timestamp venha do servidor
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (data['createdAt'] == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      
      await _occurrencesRef.add(data);
    } catch (e) {
      throw Exception('Erro ao registrar ocorrência: $e');
    }
  }

  /// Atualiza uma ocorrência existente.
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

  /// Atalho para atualizar apenas o status.
  Future<void> updateOccurrenceStatus(
    String id, 
    OccurrenceStatus status, 
    {String? resolutionDescription}
  ) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'resolutionDescription': resolutionDescription,
      };

      await _occurrencesRef.doc(id).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
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

  /// Busca uma única ocorrência pelo ID.
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