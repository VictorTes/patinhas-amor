import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService(); // Instanciando corretamente
  bool _isLoading = false;

  void _updatePassword() async {
    // 1. Validações básicas
    if (_passwordController.text.length < 6) {
      _showMsg("A senha deve ter no mínimo 6 caracteres");
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showMsg("As senhas não coincidem");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Chamando a função "blindada" do seu AuthService
      await _authService.updatePasswordAndRelease(_passwordController.text.trim());
      
      if (mounted) {
        _showMsg("Senha atualizada! Por segurança, faça login novamente.");
        
        // IMPORTANTE: Não navegamos para a /home aqui.
        // O AuthService já chamou o logout(), então o AuthWrapper (no main.dart)
        // vai detectar que o usuário é null e vai renderizar a LoginScreen sozinho.
      }
    } catch (e) {
      if (mounted) _showMsg(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange[800],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.published_with_changes_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Troca de Senha",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Por segurança, crie uma senha pessoal antes de continuar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Nova Senha", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: "Confirmar Nova Senha", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.orange)
                : ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "SALVAR E REFAZER LOGIN", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}