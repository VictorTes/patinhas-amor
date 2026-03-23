import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';
import 'package:patinhas_amor/screens/volunteer_register_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Drawer(
      child: Column(
        children: [
          // CABEÇALHO COM DADOS DINÂMICOS DO FIRESTORE
          FutureBuilder<Map<String, dynamic>?>(
            future: authService.getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  image: DecorationImage(
                    image: NetworkImage(
                        "https://www.transparenttextures.com/patterns/cubes.png"),
                    opacity: 0.1,
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.pets, color: Colors.orange, size: 35),
                ),
                accountName: Text(
                  userData?['name'] ?? 'Usuário',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail:
                    Text(userData?['email'] ?? 'E-mail não disponível'),
              );
            },
          ),

          // LISTA DE OPÇÕES DE NAVEGAÇÃO
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Início'),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.notification_important_outlined,
                color: Colors.orange),
            title: const Text('Ocorrências'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OccurrencesListScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.pets_outlined, color: Colors.green),
            title: const Text('Animais Resgatados'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AnimalsListScreen()),
              );
            },
          ),

          // ÁREA EXCLUSIVA PARA ADMIN (Verifica a Role no Firestore)
          FutureBuilder<Map<String, dynamic>?>(
            future: authService.getUserData(),
            builder: (context, snapshot) {
              // Verifica se os dados chegaram e se a role é 'admin'
              if (snapshot.hasData && snapshot.data?['role'] == 'admin') {
                return Column(
                  children: [
                    const Divider(),
                    const Padding(
                      padding:
                          EdgeInsets.only(left: 16, top: 8, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ADMINISTRAÇÃO",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined,
                          color: Colors.blueAccent),
                      title: const Text('Cadastrar Voluntário'),
                      onTap: () {
                        Navigator.pop(context); // Fecha o drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const VolunteerRegisterScreen()),
                        );
                      },
                    ),
                  ],
                );
              }
              // Se não for admin, retorna um widget vazio
              return const SizedBox.shrink();
            },
          ),

          const Spacer(), // Empurra o botão de Sair para o rodapé

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair do App',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await authService.logout();
              // O listener de autenticação no seu main.dart cuidará do redirecionamento
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}