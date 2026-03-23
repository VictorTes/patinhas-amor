import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const RoleGuard({
    super.key, 
    required this.child, 
    this.requiredRole = 'admin',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService().getUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?['role'] == requiredRole) {
          return child; // Se for admin, mostra o botão/tela
        }
        return const SizedBox.shrink(); // Se não for, some com o elemento
      },
    );
  }
}