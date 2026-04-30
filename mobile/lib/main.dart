import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:patinhas_amor/widgets/auth_wrapper.dart';
import 'package:patinhas_amor/screens/home_screen.dart';
import 'package:patinhas_amor/screens/login_screen.dart';
import 'package:patinhas_amor/screens/forgot_password_screen.dart';
import 'package:patinhas_amor/screens/campaign_form_screen.dart';
import 'package:patinhas_amor/screens/campaign_detail_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Erro ao carregar arquivo .env: $e");
  }

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
      
      // CONFIGURAÇÃO DE LOCALIZAÇÃO
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),

      // O AuthWrapper no 'home' garante que ninguém passe da porta sem login.
      home: const ConnectivityWrapper(
        child: AuthWrapper(),
      ),

      // Rotas do Aplicativo
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/criar-campanha': (context) => const CampaignFormScreen(),
        '/detalhe-campanha': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            return CampaignDetailScreen(campaignId: args);
          }
          return const Scaffold(body: Center(child: Text("Erro ao carregar campanha")));
        },
      },
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    });
  }

  // Verifica a conexão assim que o app abre
  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = results.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usei o resizeToAvoidBottomInset para evitar que o banner quebre o layout com teclado
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          if (_isOffline)
            Material(
              elevation: 4,
              child: Container(
                color: Colors.redAccent,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Modo Offline: Algumas funções podem estar limitadas",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}