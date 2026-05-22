import 'package:flutter/material.dart';
import 'package:tuna/screens/settings_screen.dart';
import 'package:tuna/screens/tuner_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuna',
      theme: ThemeData(
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const TunerScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
