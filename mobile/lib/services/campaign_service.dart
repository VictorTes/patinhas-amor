import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/campaign.dart';

class CampaignService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'campaigns';

  // Configurações do Cloudinary (Substitua pelos seus dados)
  final String cloudName = "seu_cloud_name";
  final String uploadPreset = "seu_preset";

  // Função interna para upload no Cloudinary via API REST
  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      }
      return null;
    } catch (e) {
      print("Erro upload Cloudinary: $e");
      return null;
    }
  }

  // Salvar nova campanha
  Future<void> saveCampaign(CampaignModel campaign, File? mainImage, List<File>? receipts) async {
    try {
      String? mainImageUrl;
      List<String> receiptUrls = [];

      // 1. Upload da imagem principal
      if (mainImage != null) {
        mainImageUrl = await _uploadToCloudinary(mainImage);
      }

      // 2. Upload múltiplo dos comprovantes
      if (receipts != null && receipts.isNotEmpty) {
        for (var file in receipts) {
          String? url = await _uploadToCloudinary(file);
          if (url != null) {
            receiptUrls.add(url);
          }
        }
      }

      // 3. Montar dados finais
      final data = campaign.toMap();
      data['imageUrl'] = mainImageUrl;
      data['receiptUrls'] = receiptUrls;
      data['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).add(data);
    } catch (e) {
      throw Exception('Erro ao salvar campanha: $e');
    }
  }

  // Atualizar campanha
  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Excluir campanha
  Future<void> deleteCampaign(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Stream para listagem (com o filtro de status)
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