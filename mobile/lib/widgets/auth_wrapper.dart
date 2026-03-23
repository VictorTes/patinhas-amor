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

        // 2. Se NÃO houver usuário autenticado no Firebase (Token inexistente)
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 3. Se houver usuário autenticado, validamos a existência no Firestore
        // Isso resolve o problema de usuários deletados manualmente no console
        return FutureBuilder<Map<String, dynamic>?>(
          future: authService.getUserData(),
          builder: (context, userSnapshot) {
            // Enquanto busca os dados no Firestore (nome, role, mustChangePassword)
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }

            // SE OS DADOS NÃO EXISTIREM (Usuário deletado ou banido no banco)
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              // Forçamos o logout para limpar o cache local e evitar o "usuário fantasma"
              authService.logout();
              return const LoginScreen();
            }

            // SE OS DADOS EXISTIREM, pegamos o mapa de informações
            final userData = userSnapshot.data!;

            // 4. Verificação de Troca de Senha Obrigatória
            // Se o Admin acabou de criar o voluntário, ele DEVE trocar a senha
            if (userData['mustChangePassword'] == true) {
              return const ChangePasswordScreen();
            }

            // 5. TUDO OK: Usuário autenticado, existente no banco e com senha trocada
            return const HomeScreen();
          },
        );
      },
    );
  }
}