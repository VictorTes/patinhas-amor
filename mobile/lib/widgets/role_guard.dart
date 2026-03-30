import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;
  final Widget? fallback; // Novo: permite mostrar algo caso não seja admin

  const RoleGuard({
    super.key,
    required this.child,
    this.requiredRole = 'admin',
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService().getUserData(),
      builder: (context, snapshot) {
        // 1. Enquanto carrega os dados do Firestore
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Se for uma tela inteira, mostra loading. Se for só um botão, nada.
          return fallback != null 
              ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
              : const SizedBox.shrink();
        }

        // 2. Se o usuário tiver o papel necessário
        if (snapshot.hasData && snapshot.data?['role'] == requiredRole) {
          return child;
        }

        // 3. Caso não tenha permissão
        // Se houver um fallback (ex: mensagem de erro), mostra ele. 
        // Se não (uso em botões), some com o elemento.
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}