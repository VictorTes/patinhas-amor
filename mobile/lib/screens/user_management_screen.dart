import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/widgets/role_guard.dart'; // Ajuste o caminho se necessário

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

  // Função para confirmar exclusão
  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Usuário"),
        content: Text("Tem certeza que deseja excluir $name? Esta ação não pode ser desfeita no banco de dados."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              Navigator.pop(context);
              try {
                await _authService.deleteUser(uid);
                setState(() {});
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
    // Aplicando o SEU RoleGuard para proteger a tela inteira
    return RoleGuard(
      requiredRole: 'admin', // Define o cargo necessário como string
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
                          } else if (value == 'toggle') {
                            setState(() => _isLoading = true);
                            try {
                              await _authService.updateUserStatus(user['uid'], !isActive);
                              setState(() {});
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          } else if (value == 'delete') {
                            _confirmDelete(user['uid'], user['name'] ?? 'este usuário');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text("Editar"))),
                          PopupMenuItem(
                            value: 'toggle', 
                            child: ListTile(
                              leading: Icon(isActive ? Icons.block : Icons.check_circle), 
                              title: Text(isActive ? "Desativar" : "Ativar"),
                            ),
                          ),
                          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text("Excluir"))),
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