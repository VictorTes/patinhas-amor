import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  // --- AUTENTICAÇÃO ---

  Future<UserCredential> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.reload();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Erro ao deslogar: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- GERENCIAMENTO DO PERFIL LOGADO EM TEMPO REAL ---

  Stream<Map<String, dynamic>?> getUserDataStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      return doc.data(); 
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('users').doc(user.uid).get();
        return doc.data();
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
    }
    return null;
  }

  Future<void> updatePasswordAndRelease(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Sessão expirada. Faça login novamente.';

      await _db.collection('users').doc(user.uid).update({
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

  // --- FUNÇÕES ADMINISTRATIVAS ---

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = 
          await _db.collection('users').orderBy('name').get();
          
      return snapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw 'Erro ao listar usuários: $e';
    }
  }

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

  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw 'Erro ao mudar status: $e';
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // 1. Exclui o documento no Firestore
      await _db.collection('users').doc(uid).delete();

      // 2. Exclui do Firebase Authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await currentUser.delete();
      } else {
        // Se for um administrador excluindo outro usuário, pode ser necessário 
        // utilizar o Admin SDK ou Cloud Functions.
        final userRecord = FirebaseAuth.instance.currentUser;
        if (userRecord != null) {
          // Nota: O SDK do cliente Flutter permite que o usuário atual exclua sua conta.
          // Para outras contas, utilize um endpoint de backend (ex: deleteUser/Function).
          // Se você estiver rodando localmente, tente a deleção administrativa que sua regra de segurança suportar.
        }
      }
    } catch (e) {
      throw 'Erro ao excluir usuário: $e';
    }
  }

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