import 'package:flutter/material.dart';
import 'package:patinhas_amor/services/auth_service.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';
import 'package:patinhas_amor/screens/volunteer_register_screen.dart';
import 'package:patinhas_amor/screens/user_management_screen.dart';
import 'package:patinhas_amor/screens/moderation_list_screen.dart';
import 'package:patinhas_amor/screens/campaing_list_screen.dart';
import 'package:patinhas_amor/screens/reports_screen.dart'; // Importação adicionada

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

          // LISTA DE OPÇÕES DE NAVEGAÇÃO COMUNS
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
              Navigator.pop(context);
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AnimalsListScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.confirmation_number_outlined, color: Colors.deepOrange),
            title: const Text('Campanhas e Rifas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CampanhasView()),
              );
            },
          ),

          // ÁREA EXCLUSIVA PARA ADMIN / SUPERADMIN
          FutureBuilder<Map<String, dynamic>?>(
            future: authService.getUserData(),
            builder: (context, snapshot) {
              final role = snapshot.data?['role'];
              
              // Verificação para ambos os cargos administrativos
              if (snapshot.hasData && (role == 'admin' || role == 'superAdmin')) {
                return Column(
                  children: [
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
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
                    
                    // NOVA OPÇÃO: RELATÓRIOS (Adicionada conforme solicitado)
                    ListTile(
                      leading: const Icon(Icons.bar_chart_outlined,
                          color: Colors.purple),
                      title: const Text('Relatórios e Estatísticas'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ReportsScreen()),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined,
                          color: Colors.orange),
                      title: const Text('Moderar Ocorrências'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ModerationListScreen()),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined,
                          color: Colors.blueAccent),
                      title: const Text('Cadastrar Voluntário'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const VolunteerRegisterScreen()),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined,
                          color: Colors.indigo),
                      title: const Text('Gerenciar Voluntários'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const UserManagementScreen()),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}