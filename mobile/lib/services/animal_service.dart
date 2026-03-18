import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Importe o dotenv
import 'package:patinhas_amor/models/animal.dart';

/// Service class responsible for handling all Firestore and Cloudinary communication
class AnimalService {
  // Referência para a coleção "animals" no Firestore
  final CollectionReference _animalsRef =
      FirebaseFirestore.instance.collection('animals');

  // --- CONFIGURAÇÃO CLOUDINARY VIA DOTENV ---
  // 2. Buscamos as chaves do arquivo .env
  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'padrão');

  /// Faz o upload de uma imagem para o Cloudinary e retorna a URL segura.
  Future<String?> uploadAnimalImage(File imageFile) async {
    // Verificação de segurança caso as chaves não existam
    if (_cloudName.isEmpty) {
      print('Erro: CLOUDINARY_CLOUD_NAME não encontrado no arquivo .env');
      return null;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      // Lendo a resposta do stream
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseBody);
        return jsonMap['secure_url'] as String;
      } else {
        // Log detalhado para te ajudar a debugar se o erro 400 voltar
        print('Erro Cloudinary (${response.statusCode}): $responseBody');
        return null;
      }
    } catch (e) {
      print('Erro ao subir imagem: $e');
      return null;
    }
  }

  /// Fetches all animals registered in Firestore.
  Future<List<Animal>> fetchAnimals() async {
    try {
      final QuerySnapshot snapshot = await _animalsRef.get();

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
  Future<Animal> createAnimal(Animal animal) async {
    try {
      final DocumentReference docRef = await _animalsRef.add(animal.toJson());
      final DocumentSnapshot doc = await docRef.get();

      return Animal.fromJson(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
    } catch (e) {
      throw Exception('Failed to create animal in Firestore: $e');
    }
  }

  /// Atualiza um registro de animal existente no Firestore.
  Future<void> updateAnimal(Animal animal) async {
    if (animal.id == null) return;
    try {
      await _animalsRef.doc(animal.id).update(animal.toJson());
    } catch (e) {
      throw Exception('Falha ao atualizar animal: $e');
    }
  }
  
  /// Deleta um registro de animal no Firestore.
  Future<void> deleteAnimal(String animalId) async {
    try {
      await _animalsRef.doc(animalId).delete();
    } catch (e) {
      throw Exception('Falha ao deletar animal no Firestore: $e');
    }
  }

  /// Stream para ouvir mudanças em tempo real (Real-time)
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

  void dispose() {
    // Firestore e Cloudinary gerenciam o ciclo de vida automaticamente
  }
}