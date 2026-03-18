import 'package:flutter/material.dart';

import 'package:patinhas_amor/screens/home_screen.dart';

/// Main entry point for the Patinhas e Amor application.
///
/// This app is used internally by the NGO team to manage reports of
/// animal abandonment or abuse submitted by the public.
void main() {
  runApp(const PatinhasAmorApp());
}

/// Root widget of the application.
///
/// Sets up the MaterialApp with theme configuration.
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
      // Initial screen is now the HomeScreen
      home: const HomeScreen(),
    );
  }
}
