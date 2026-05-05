import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/widgets/role_guard.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Função para abrir o diálogo de edição
  void _showEditDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final phoneController = TextEditingController(text: user['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Usuário"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nome",
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), 
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR")
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              Navigator.pop(context);
              try {
                await _authService.updateUserDetails(
                  user['uid'], 
                  nameController.text, 
                  phoneController.text
                );
                setState(() {}); 
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  // Função para confirmar exclusão no Authentication e Firestore
  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Usuário"),
        content: Text("Tem certeza que deseja excluir $name? Esta ação removerá o usuário do sistema de autenticação e do banco de dados."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR")
          ),
          TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              Navigator.pop(context);
              try {
                // 1. Exclui o documento do Firestore (ajuste a coleção se necessário, ex: 'users')
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();

                // 2. Exclui do Firebase Authentication
                // Nota: se for deletar um usuário diferente do atual, o SDK nativo do Flutter 
                // não suporta essa operação diretamente pelo cliente, sendo necessário Admin SDK/Cloud Function.
                // Caso seja o administrador deletando um usuário e você tenha problemas com permissões do Auth,
                // certifique-se de usar o Firebase Admin. 
                // Se o usuário atual estiver deletando a si mesmo, o user.delete() funcionará.
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && currentUser.uid == uid) {
                  await currentUser.delete();
                } else {
                  // Opcionalmente, chame seu próprio serviço ou método de remoção caso tenha um endpoint para Admin:
                  await _authService.deleteUser(uid);
                }

                setState(() {});
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro de autenticação: ${e.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'admin',
      fallback: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("Acesso negado. Apenas administradores podem ver esta tela."),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Voltar"),
              ),
            ],
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("Gerenciar Voluntários")),
        body: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _authService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Nenhum usuário encontrado."));
                }

                final users = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final bool isActive = user['isActive'] ?? true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user['role'] == 'admin' ? Colors.red[100] : Colors.orange[100],
                        child: Icon(
                          user['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                          color: user['role'] == 'admin' ? Colors.red : Colors.orange,
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Sem nome', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.grey,
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        )
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          Text("Fone: ${user['phone'] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                          Text(
                            "Cargo: ${user['role']?.toString().toUpperCase()}", 
                            style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditDialog(user);
                          } else if (value == 'delete') {
                            _confirmDelete(user['uid'], user['name'] ?? 'este usuário');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit', 
                            child: ListTile(
                              leading: Icon(Icons.edit), 
                              title: Text("Editar")
                            )
                          ),
                          const PopupMenuItem(
                            value: 'delete', 
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red), 
                              title: Text("Excluir")
                            )
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}