import 'dart:math'; // Para gerar a senha aleatória
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerRegisterScreen extends StatefulWidget {
  const VolunteerRegisterScreen({super.key});

  @override
  State<VolunteerRegisterScreen> createState() => _VolunteerRegisterScreenState();
}

class _VolunteerRegisterScreenState extends State<VolunteerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  /// Função principal para cadastrar no Auth, Firestore e Notificar
  Future<void> _registerVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Geração de senha aleatória (MUDAR + 6 números)
      final random = Random();
      final randomNumber = 100000 + random.nextInt(900000); 
      final temporaryPassword = "MUDAR$randomNumber";

      // 2. Criar o usuário no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: temporaryPassword, 
      );

      // 3. Salvar os dados no Firestore usando o UID gerado
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'volunteer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Abrir WhatsApp com as credenciais geradas
      await _sendWhatsAppNotification(temporaryPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voluntário cadastrado e notificado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao cadastrar';
      if (e.code == 'email-already-in-use') message = 'Este e-mail já está em uso.';
      if (e.code == 'weak-password') message = 'A senha gerada foi considerada fraca.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Monta a mensagem e abre o WhatsApp
  Future<void> _sendWhatsAppNotification(String password) async {
    // Remove caracteres não numéricos do telefone
    String phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), "");
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    
    String message = "Olá $name! Bem-vindo(a) à Patinhas e Amor. 🐾\n\n"
        "Seu acesso ao App está pronto:\n"
        "Login: $email\n"
        "Senha Temporária: $password\n\n"
        "Baixe o app e, por segurança, altere sua senha após o primeiro acesso.";

    var url = Uri.parse("https://wa.me/55$phone?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Não foi possível abrir o WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Voluntário'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 80, color: Colors.orange),
                  const SizedBox(height: 20),
                  const Text(
                    'Cadastre um novo membro. Uma senha aleatória será gerada e enviada via WhatsApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail de Acesso',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v!.contains('@') ? null : 'E-mail inválido',
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo Telefone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp (com DDD)',
                      hintText: '47999999999',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    validator: (v) => v!.length < 10 ? 'Telefone muito curto' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botão de Ação
                  ElevatedButton(
                    onPressed: _registerVolunteer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'CADASTRAR E NOTIFICAR',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}