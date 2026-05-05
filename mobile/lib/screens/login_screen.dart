import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/screens/change_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Lógica de Login com verificação de senha obrigatória
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Realiza a autenticação
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Busca os dados complementares no Firestore
      final userData = await _authService.getUserData();

      if (mounted) {
        // 3. Verifica se o campo 'mustChangePassword' está como true
        if (userData != null && userData['mustChangePassword'] == true) {
          // Se for um novo voluntário com senha temporária, vai para a troca
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
          );
        } else {
          // Se já for admin ou voluntário antigo, vai para a home
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        // Proteção para mensagens técnicas do Firebase, exibindo apenas um erro padrão no front-end
        String errorMessage = e.toString();
        if (errorMessage.contains("projects/")) {
          errorMessage = 'Ocorreu um erro ao processar seu login. Verifique seus dados e tente novamente.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Recuperação de senha (Esqueci minha senha)
  void _handleForgotPassword() async {
    Navigator.pushNamed(context, '/forgot-password');
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://github.com/VictorTes/patinhas-amor/blob/main/POLITICA.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link da política.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO E TÍTULO
                Icon(Icons.pets, size: 80, color: Colors.orange[400]),
                const SizedBox(height: 16),
                Text(
                  'Patinhas e Amor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestão de Resgates e Doações',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 48),

                // CAMPO DE E-MAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => 
                      value!.isEmpty ? 'Informe seu e-mail' : null,
                ),
                const SizedBox(height: 16),

                // CAMPO DE SENHA
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe sua senha';
                    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                    return null;
                  },
                ),

                // ESQUECI MINHA SENHA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // BOTÃO DE LOGIN
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 20),
                const Text(
                  "Acesso restrito a voluntários cadastrados.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

                // TERMOS DE POLÍTICA DE PRIVACIDADE
                const SizedBox(height: 24),
                Column(
                  children: [
                    const Text(
                      'Ao entrar, você concorda com a nossa',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _launchPrivacyPolicy,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Política de Privacidade',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}