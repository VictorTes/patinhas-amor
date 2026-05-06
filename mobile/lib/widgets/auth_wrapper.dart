import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/screens/login_screen.dart';
import 'package:patinhas_amor/screens/home_screen.dart';
import 'package:patinhas_amor/screens/change_password_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        // A GRANDE SACADA DA ARQUITETURA: 
        // Aninhamos o segundo StreamBuilder incondicionalmente. Se não houver usuário,
        // passamos um Stream vazio. Isso garante que a hierarquia do LoginScreen NUNCA 
        // mude na Widget Tree, preservando os campos de texto e garantindo o SnackBar.
        return StreamBuilder<Map<String, dynamic>?>(
          stream: user != null ? authService.getUserDataStream() : Stream.value(null),
          builder: (context, userSnapshot) {
            
            // 1. Verifica conexão inicial com Firebase Auth
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }

            // 2. Se não houver usuário logado (Token expirado ou não autenticado)
            if (user == null) {
              return const LoginScreen();
            }

            // 3. Usuário logado: Ouvindo dados do Firestore em tempo real
            // Enquanto carrega, mantemos a LoginScreen na tela para preservar o botão girando
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoginScreen();
            }

            // Se as regras do Firestore bloquearem (PERMISSION_DENIED gera um erro aqui)
            // ou se o documento do usuário não existir
            if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
              _forceLogout(authService);
              return const LoginScreen();
            }

            final userData = userSnapshot.data!;

            // --- BLOQUEIO EM TEMPO REAL ---
            if (userData['isActive'] == false) {
              _forceLogout(authService);
              return const LoginScreen();
            }

            // Verificação de Troca de Senha Obrigatória
            if (userData['mustChangePassword'] == true) {
              return const ChangePasswordScreen();
            }

            // TUDO OK: Vai para a Home
            return const HomeScreen();
          },
        );
      },
    );
  }

  /// Função auxiliar para deslogar sem causar conflitos de build
  void _forceLogout(AuthService authService) {
    Future.microtask(() async {
      await authService.logout();
    });
  }
}