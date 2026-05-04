import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patinhas_amor/services/auth_service.dart';
// Importe a tela de FAQ caso vá criá-la:
// import 'package:patinhas_amor/screens/faq_screen.dart';
import 'package:patinhas_amor/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Carregando...';
  String _buildNumber = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Versão indisponível';
      });
    }
  }

  // Lógica para enviar e-mail de suporte
  Future<void> _contactSupport() async {
    // Substitua pelo e-mail da sua ONG ou de suporte
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'suporte@patinhasamor.com',
      queryParameters: {'subject': 'Suporte / Bug - App Patinhas Amor'},
    );

    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o aplicativo de e-mail.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Lógica de logout
  void _handleLogout() async {
    try {
      // Exibe um diálogo de confirmação antes de sair
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Sair',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _authService.logout(); // Ajuste o método conforme seu Auth Service
        
        if (mounted) {
          // Redireciona para a tela de login e remove as telas anteriores do histórico
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login', // Altere para a sua rota de login caso não use nomeada
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // Seção de Ajuda
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.orange),
            title: const Text('FAQ / Ajuda'),
            subtitle: const Text('Perguntas frequentes e como usar o app'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar para a tela de FAQ
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
            },
          ),
          const Divider(),

          // Seção de Contato/Suporte
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.orange),
            title: const Text('Suporte / Bugs'),
            subtitle: const Text('Entre em contato com o desenvolvedor'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _contactSupport,
          ),
          const Divider(),

          // Seção de Versão do App (Informativo)
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('Versão do App'),
            subtitle: Text('$_appVersion (Build $_buildNumber)'),
          ),
          const Divider(),

          // Seção de Logout
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}