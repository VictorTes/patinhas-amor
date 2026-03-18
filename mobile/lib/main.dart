import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Importe o pacote
import 'package:patinhas_amor/screens/home_screen.dart';

void main() async {
  // Garante que as comunicações nativas estejam prontas
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Carrega o arquivo .env antes de tudo
    // Certifique-se de que o arquivo se chama exatamente ".env" na raiz do projeto
    await dotenv.load(fileName: ".env");
    print("Variáveis de ambiente carregadas com sucesso!");
  } catch (e) {
    print("Erro ao carregar arquivo .env: $e");
    // Dica: Verifique se o arquivo .env está listado nos assets do pubspec.yaml
  }

  // Inicializa o Firebase
  await Firebase.initializeApp();
  
  runApp(const PatinhasAmorApp());
}

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
      home: const HomeScreen(),
    );
  }
}