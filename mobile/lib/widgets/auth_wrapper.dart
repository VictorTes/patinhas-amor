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

        // 3. Usuário logado: Agora ouvimos os dados do Firestore EM TEMPO REAL
        return StreamBuilder<Map<String, dynamic>?>(
          stream: authService.getUserDataStream(), // Usando o novo Stream
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }

            // Se o documento do usuário não existir (deletado do banco)
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              Future.microtask(() => authService.logout());
              return const LoginScreen();
            }

            final userData = userSnapshot.data!;

            // --- BLOQUEIO EM TEMPO REAL ---
            // Se isActive mudar para false no banco, o app volta para o Login instantaneamente
            if (userData['isActive'] == false) {
              Future.microtask(() => authService.logout());
              return const LoginScreen();
            }

            // Verificação de Troca de Senha Obrigatória
            if (userData['mustChangePassword'] == true) {
              return const ChangePasswordScreen();
            }

            // TUDO OK
            return const HomeScreen();
          },
        );
      },
    );
  }
}