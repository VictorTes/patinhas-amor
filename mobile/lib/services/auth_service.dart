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

  // --- GERENCIAMENTO DO PERFIL LOGADO ---

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
  Future<void> updatePasswordAndRelease(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Sessão expirada. Faça login novamente.';

      final String uid = user.uid;

      await _db.collection('users').doc(uid).update({
        'mustChangePassword': false,
      });

      await user.updatePassword(newPassword);
      await logout();

    } on FirebaseAuthException catch (e) {
      await logout();
      if (e.code == 'requires-recent-login') {
        throw 'Por segurança, saia e entre novamente antes de definir a nova senha.';
      }
      throw _handleAuthError(e);
    } catch (e) {
      await logout();
      throw 'Erro ao atualizar dados: $e';
    }
  }

  // --- FUNÇÕES ADMINISTRATIVAS (GERENCIAR OUTROS USUÁRIOS) ---

  /// Lista todos os usuários cadastrados no Firestore
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').orderBy('name').get();
      return snapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();
    } catch (e) {
      throw 'Erro ao listar usuários: $e';
    }
  }

  /// Atualiza Nome e Telefone de um voluntário
  Future<void> updateUserDetails(String uid, String name, String phone) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
      });
    } catch (e) {
      throw 'Erro ao atualizar usuário: $e';
    }
  }

  /// Ativa ou Desativa o acesso de um usuário
  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw 'Erro ao mudar status: $e';
    }
  }

  /// Exclui o documento do usuário no Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      throw 'Erro ao excluir usuário: $e';
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