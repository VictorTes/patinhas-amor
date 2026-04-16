import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/campaign.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class CampaignService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'campaigns';

  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'padrão');

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'campanhas'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      }
      return null;
    } catch (e) {
      print("Erro upload Cloudinary: $e");
      return null;
    }
  }

  /// Salva ou Atualiza uma campanha (Lógica Corrigida)
  Future<void> saveCampaign(CampaignModel campaign, File? mainImage, List<File>? receipts) async {
    try {
      // Se a campanha já tem ID, buscamos as URLs atuais para não perdê-las caso não envie arquivos novos
      String? mainImageUrl = campaign.imageUrl;
      List<String> receiptUrls = List.from(campaign.receiptUrls ?? []);

      // 1. Upload da imagem principal (só faz se houver arquivo novo)
      if (mainImage != null) {
        String? uploadedUrl = await _uploadToCloudinary(mainImage);
        if (uploadedUrl != null) mainImageUrl = uploadedUrl;
      }

      // 2. Upload múltiplo dos comprovantes (só faz se houver arquivos novos)
      if (receipts != null && receipts.isNotEmpty) {
        for (var file in receipts) {
          String? url = await _uploadToCloudinary(file);
          if (url != null) {
            receiptUrls.add(url);
          }
        }
      }

      // 3. Montar dados para o Firestore
      final data = campaign.toMap();
      data['imageUrl'] = mainImageUrl;
      data['receiptUrls'] = receiptUrls;

      // 4. Lógica de Decisão: Editar ou Criar
      if (campaign.id != null && campaign.id!.isNotEmpty) {
        // ATUALIZAR: Usa o ID existente
        await _firestore.collection(_collection).doc(campaign.id).update(data);
      } else {
        // CRIAR NOVO: Adiciona timestamp de criação
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection(_collection).add(data);
      }
    } catch (e) {
      throw Exception('Erro ao processar campanha: $e');
    }
  }

  // Atualização parcial de campos específicos
  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar campos: $e');
    }
  }

  Future<void> deleteCampaign(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Stream<List<CampaignModel>> getCampaignsStream(String? statusFilter) {
    Query query = _firestore.collection(_collection).orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter != 'todas') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CampaignModel.fromFirestore(doc)).toList();
    });
  }
}