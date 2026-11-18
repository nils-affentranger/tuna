import 'package:flutter/material.dart';
import 'package:tuna/screens/instruments_screen.dart';
import 'package:tuna/screens/metronome_screen.dart';
import 'package:tuna/screens/settings_screen.dart';
import 'package:tuna/screens/tuner_screen.dart';
import 'package:tuna/services/app_controller.dart';
import 'package:tuna/widgets/tuna_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TunaApp());
}

class TunaApp extends StatefulWidget {
  const TunaApp({super.key});

  @override
  State<TunaApp> createState() => _TunaAppState();
}

class _TunaAppState extends State<TunaApp> {
  final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuna',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ).copyWith(primary: Colors.black, secondary: Colors.black),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.black,
          inactiveTrackColor: Colors.black26,
          thumbColor: Colors.black,
          overlayColor: Color(0x22222222),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.black;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.black
                : Colors.black26;
          }),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
      ),
      builder: (context, child) {
        return TunaScope(
          controller: _controller,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const TunerScreen(),
      routes: {
        '/metronome': (context) => const MetronomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/instruments': (context) => const InstrumentsScreen(),
      },
    );
  }
}
