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
      print('ERRO: CLOUDINARY_CLOUD_NAME não configurado no .env');
      return null;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'animais_ong' // Organização por pastas
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseBody);
        return jsonMap['secure_url'] as String;
      } else {
        print('ERRO Cloudinary (${response.statusCode}): $responseBody');
        return null;
      }
    } catch (e) {
      print('EXCEÇÃO ao subir imagem: $e');
      return null;
    }
  }

  /// Busca todos os animais (Chamada única). 
  /// Adicionado ordenação por data de resgate (decrescente).
  Future<List<Animal>> fetchAnimals() async {
    try {
      final QuerySnapshot snapshot = await _animalsRef
          .orderBy('rescueDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Animal.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      print('Erro fetchAnimals: $e');
      throw Exception('Falha ao carregar animais: $e');
    }
  }

  /// Cria um novo registro de animal no Firestore.
  Future<Animal> createAnimal(Animal animal) async {
    try {
      // O Firestore mapeia automaticamente o objeto via toJson()
      final DocumentReference docRef = await _animalsRef.add(animal.toJson());
      final DocumentSnapshot doc = await docRef.get();

      return Animal.fromJson(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
    } catch (e) {
      print('Erro createAnimal: $e');
      throw Exception('Falha ao criar registro: $e');
    }
  }

  /// Atualiza um registro de animal existente.
  Future<void> updateAnimal(Animal animal) async {
    if (animal.id == null || animal.id!.isEmpty) {
      throw Exception('Não é possível atualizar um animal sem ID.');
    }
    
    try {
      await _animalsRef.doc(animal.id).update(animal.toJson());
    } catch (e) {
      print('Erro updateAnimal: $e');
      throw Exception('Falha ao atualizar dados: $e');
    }
  }
  
  /// Deleta um registro de animal.
  Future<void> deleteAnimal(String animalId) async {
    try {
      await _animalsRef.doc(animalId).delete();
    } catch (e) {
      print('Erro deleteAnimal: $e');
      throw Exception('Falha ao deletar registro: $e');
    }
  }

  /// Stream para ouvir mudanças em tempo real.
  /// Ideal para a tela de listagem (Dashboard).
  Stream<List<Animal>> getAnimalsStream() {
    return _animalsRef
        .orderBy('rescueDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Animal.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    });
  }

  void dispose() {
    // O Firebase gerencia as conexões internamente.
  }
}