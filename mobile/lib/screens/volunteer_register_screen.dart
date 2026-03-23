import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patinhas_amor/services/auth_service.dart';

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
  
  String _selectedRole = 'volunteer'; // Valor padrão
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermission(); // Proteção de rota logo ao abrir a tela
  }

  /// Verifica se quem está tentando usar esta tela é realmente um Admin
  void _checkPermission() async {
    final userData = await AuthService().getUserData();
    if (userData == null || userData['role'] != 'admin') {
      if (mounted) {
        Navigator.pop(context); // Expulsa da tela
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acesso restrito: Apenas administradores podem cadastrar usuários."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Função para cadastrar sem deslogar o Admin atual
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Criamos uma instância secundária para não afetar o login atual do Admin
    // Isso evita que o Firebase faça o login automático do novo usuário no app
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('SecondaryApp');
    }
    
    FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // 1. Geração de senha aleatória
      final random = Random();
      final randomNumber = 100000 + random.nextInt(900000); 
      final temporaryPassword = "MUDAR$randomNumber";

      // 2. Criar o usuário na instância secundária
      UserCredential userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: temporaryPassword, 
      );

      // 3. Salvar no Firestore (usando a instância principal do Firestore)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole, 
        'mustChangePassword': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Desloga a conta secundária e deleta a instância temporária
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      // 5. Notifica via WhatsApp
      await _sendWhatsAppNotification(temporaryPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao cadastrar';
      if (e.code == 'email-already-in-use') message = 'Este e-mail já está em uso.';
      if (e.code == 'weak-password') message = 'A senha gerada é muito fraca.';
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendWhatsAppNotification(String password) async {
    String phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), "");
    String roleLabel = _selectedRole == 'admin' ? "Administrador(a)" : "Voluntário(a)";
    
    String message = "Olá ${_nameController.text.trim()}! 🐾\n\n"
        "Seu acesso como *$roleLabel* no App Patinhas de Amor está pronto!\n"
        "Login: ${_emailController.text.trim()}\n"
        "Senha Temporária: $password\n\n"
        "Por segurança, o app solicitará a troca da senha no seu primeiro acesso.";

    var url = Uri.parse("https://wa.me/55$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Usuário'),
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
                  
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail de Acesso', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v!.contains('@') ? null : 'E-mail inválido',
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Nível de Acesso',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'volunteer', child: Text('Voluntário')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'WhatsApp (com DDD)', prefixIcon: Icon(Icons.phone_android)),
                    validator: (v) => v!.length < 10 ? 'Telefone inválido' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CADASTRAR E NOTIFICAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}