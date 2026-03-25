import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:patinhas_amor/models/animal.dart';

/// Service responsável por gerenciar os animais da ONG no Firestore e Cloudinary.
class AnimalService {
  // Referência para a coleção "animals" no Firestore
  final CollectionReference _animalsRef =
      FirebaseFirestore.instance.collection('animals');

  // --- CONFIGURAÇÃO CLOUDINARY VIA DOTENV ---
  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'padrão');

  /// Faz o upload de uma imagem para o Cloudinary na pasta específica 'animais_ong'.
  Future<String?> uploadAnimalImage(File imageFile) async {
    if (_cloudName.isEmpty) {
      print('Erro: CLOUDINARY_CLOUD_NAME não encontrado no arquivo .env');
      return null;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'animais_ong' // <--- ORGANIZA EM PASTA NO CLOUDINARY
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseBody);
        return jsonMap['secure_url'] as String;
      } else {
        print('Erro Cloudinary (${response.statusCode}): $responseBody');
        return null;
      }
    } catch (e) {
      print('Erro ao subir imagem do animal: $e');
      return null;
    }
  }

  /// Busca todos os animais registrados no Firestore (chamada única).
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
      throw Exception('Falha ao carregar animais do Firestore: $e');
    }
  }

  /// Cria um novo registro de animal no Firestore.
  Future<Animal> createAnimal(Animal animal) async {
    try {
      final DocumentReference docRef = await _animalsRef.add(animal.toJson());
      final DocumentSnapshot doc = await docRef.get();

      return Animal.fromJson(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
    } catch (e) {
      throw Exception('Falha ao criar animal no Firestore: $e');
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

  /// Stream para ouvir mudanças em tempo real (Real-time).
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
    // Recursos gerenciados automaticamente pelo Firebase/HTTP
  }
}