import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importação do Firebase
import 'package:patinhas_amor/screens/home_screen.dart';

/// Ponto de entrada principal para a aplicação Patinhas e Amor.
void main() async {
  // Garante que as comunicações nativas do Flutter estejam prontas antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações do seu arquivo google-services.json
  await Firebase.initializeApp();

  runApp(const PatinhasAmorApp());
}

/// Widget raiz da aplicação.
class PatinhasAmorApp extends StatelessWidget {
  const PatinhasAmorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patinhas e Amor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      // Tela inicial do App
      home: const HomeScreen(),
    );
  }
}