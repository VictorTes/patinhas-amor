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
        // 1. Verifica conexão inicial com Firebase Auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        // 2. Se não houver usuário logado (Token expirado ou Logout)
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        // 3. Usuário logado: Ouvindo dados do Firestore em tempo real
        return StreamBuilder<Map<String, dynamic>?>(
          stream: authService.getUserDataStream(),
          builder: (context, userSnapshot) {
            // Enquanto carrega os dados do Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }

            // Se o documento do usuário não existir (deletado do banco por engano)
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              _forceLogout(authService);
              return const LoginScreen();
            }

            final userData = userSnapshot.data!;

            // --- BLOQUEIO EM TEMPO REAL ---
            // Se isActive mudar para false enquanto o usuário usa o app
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