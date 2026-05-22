import 'package:flutter/material.dart';
import 'package:tuna/widgets/top_bar.dart';

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
            fontWeight: FontWeight.w200,
            color: Colors.black,
          ),
        ),
      ),
      home: Scaffold(
        body: Column(
          children: [
            TopBar(
              buttonRight: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () { print('settings'); },
              ),
              buttonLeft: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black),
                onPressed: () { print('help'); },
              ),
            ),
          ],
        )
      ),
    );
  }
}
