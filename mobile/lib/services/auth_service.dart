import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      debugPrint("Erro ao deslogar: $e");
    }
  }

  /// Resetar senha (Esqueci minha senha)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- GERENCIAMENTO DE DADOS ---

  /// Buscar dados do perfil do usuário logado
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        return doc.exists ? doc.data() as Map<String, dynamic>? : null;
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
    }
    return null;
  }

  /// Altera a senha e marca 'mustChangePassword' como false.
  /// A ordem aqui é CRÍTICA para evitar o bug de sessão perdida.
  Future<void> updatePasswordAndRelease(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Sessão expirada. Faça login novamente.';

      final String uid = user.uid;

      // 1. PRIMEIRO: Atualiza o Firestore.
      // Fazemos isso enquanto o token de acesso ainda é válido.
      await _db.collection('users').doc(uid).update({
        'mustChangePassword': false,
      });

      // 2. DEPOIS: Atualiza a senha no Authentication.
      // Esta operação invalida o token atual imediatamente.
      await user.updatePassword(newPassword);

      // 3. FINALIZA: Força o logout.
      // Mesmo que o Firebase dê erro de "token inválido" aqui, o catch vai garantir o logout.
      await logout();

    } on FirebaseAuthException catch (e) {
      // Caso a senha tenha sido alterada mas o logout falhou por token, forçamos o deslogue.
      await logout();
      
      if (e.code == 'requires-recent-login') {
        throw 'Por segurança, saia e entre novamente antes de definir a nova senha.';
      }
      throw _handleAuthError(e);
    } catch (e) {
      // Erro genérico: desloga para não deixar o app em estado inconsistente
      await logout();
      throw 'Erro ao atualizar dados: $e';
    }
  }

  // --- UTILITÁRIOS ---

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'weak-password':
        return 'A senha é muito fraca (mínimo 6 caracteres).';
      case 'requires-recent-login':
        return 'Sessão expirada. Faça login novamente.';
      default:
        return 'Erro: ${e.message ?? "Tente novamente."}';
    }
  }
}