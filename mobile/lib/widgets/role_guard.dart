import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;
  final Widget? fallback;

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
        // 1. Tratamento de Erro Crítico (Ex: Falha de conexão ou Firestore offline)
        if (snapshot.hasError) {
          debugPrint("Erro no RoleGuard: ${snapshot.error}");
          return fallback ?? const SizedBox.shrink();
        }

        // 2. Enquanto carrega os dados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return fallback != null 
              ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange))) 
              : const SizedBox.shrink();
        }

        // 3. Verificação de Dados e Permissões
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          
          // TRAVA DE SEGURANÇA: Se o usuário estiver inativo, ele não vê o conteúdo protegido
          if (data['isActive'] == false) {
            return fallback ?? const SizedBox.shrink();
          }

          // Verificação da Role
          if (data['role'] == requiredRole) {
            return child;
          }
        }

        // 4. Caso não tenha permissão ou documento não exista
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}