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
      builder: (context, snapshot) {
        // 1. Enquanto verifica a conexão inicial com o Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        // 2. Se NÃO houver usuário autenticado no Firebase (Token inexistente ou Logout)
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 3. Se houver usuário autenticado, validamos os dados no Firestore
        return FutureBuilder<Map<String, dynamic>?>(
          future: authService.getUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }

            // SE OS DADOS NÃO EXISTIREM (Usuário deletado)
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              Future.microtask(() => authService.logout());
              return const LoginScreen();
            }

            final userData = userSnapshot.data!;

            // --- NOVO BLOQUEIO DE SEGURANÇA ---
            // Verifica se o campo 'isActive' é falso. 
            // Se for falso, o ADM desativou a conta, então expulsamos o usuário.
            if (userData['isActive'] == false) {
              Future.microtask(() => authService.logout());
              return const LoginScreen();
            }
            // ----------------------------------

            // 4. Verificação de Troca de Senha Obrigatória
            if (userData['mustChangePassword'] == true) {
              return const ChangePasswordScreen();
            }

            // 5. TUDO OK: Usuário autenticado, ativo e com senha em dia
            return const HomeScreen();
          },
        );
      },
    );
  }
}