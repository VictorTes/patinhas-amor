import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream que avisa o app se o usuário está logado ou não
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- AUTENTICAÇÃO ---

  /// Função para Logar
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  /// Função para Deslogar
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Erro ao deslogar: $e");
    }
  }

  /// Resetar senha (Esqueci minha senha - envia e-mail oficial do Firebase)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao processar pedido de recuperação.';
    }
  }

  // --- GERENCIAMENTO DE DADOS E PERMISSÕES ---

  /// Buscar dados do perfil do usuário logado (nome, role, mustChangePassword, etc)
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        } else {
          print("Aviso: Documento do usuário ${user.uid} não existe no Firestore.");
          return null;
        }
      }
    } catch (e) {
      print("Erro ao buscar dados do usuário: $e");
      return null;
    }
    return null;
  }

  /// Altera a senha do usuário atual e marca 'mustChangePassword' como false
  /// Útil para o primeiro acesso do voluntário
  Future<void> updatePasswordAndRelease(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. Atualiza a senha no Authentication
        await user.updatePassword(newPassword);

        // 2. Atualiza o Firestore para que ele não precise trocar de novo
        await _db.collection('users').doc(user.uid).update({
          'mustChangePassword': false,
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Por segurança, faça login novamente antes de alterar a senha.';
      }
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao atualizar dados: $e';
    }
  }

  // --- UTILITÁRIOS ---

  /// Tratamento de erros centralizado para mensagens em Português
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'E-mail ou senha incorretos. Verifique suas credenciais.';
      case 'user-disabled':
        return 'Este usuário foi desativado pela administração.';
      case 'too-many-requests':
        return 'Muitas tentativas bloqueadas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique seu Wi-Fi.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Ação de segurança: Faça login novamente para prosseguir.';
      default:
        return 'Erro ao acessar: ${e.message ?? "Tente novamente."}';
    }
  }
}