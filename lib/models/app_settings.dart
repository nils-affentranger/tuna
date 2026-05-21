import 'package:flutter/material.dart';

enum TickSoundType {
  classic,
  woodblock,
  digital;

  String get displayName {
    switch (this) {
      case TickSoundType.classic:
        return 'Classic';
      case TickSoundType.woodblock:
        return 'Woodblock';
      case TickSoundType.digital:
        return 'Digital';
    }
  }
}

class AppSettings {
  static const bool defaultKeepDeviceAwake = false;
  static const bool defaultSaveEnergy = false;
  static const int defaultColorOnCorrectHex = 0xFF2ECC71;
  static const double defaultTuningTolerance = 1.0;
  static const TickSoundType defaultTickSound = TickSoundType.classic;
  static const bool defaultFlashOnBeat = false;

  final bool keepDeviceAwake;
  final bool saveEnergy;
  final int colorOnCorrectHex;
  final double tuningTolerance;
  final TickSoundType tickSound;
  final bool flashOnBeat;

  AppSettings({
    required this.keepDeviceAwake,
    required this.saveEnergy,
    required this.colorOnCorrectHex,
    required this.tuningTolerance,
    required this.tickSound,
    required this.flashOnBeat,
  });

  Color get colorOnCorrect => Color(colorOnCorrectHex);

  factory AppSettings.defaultSettings() {
    return AppSettings(
      keepDeviceAwake: defaultKeepDeviceAwake,
      saveEnergy: defaultSaveEnergy,
      colorOnCorrectHex: defaultColorOnCorrectHex,
      tuningTolerance: defaultTuningTolerance,
      tickSound: defaultTickSound,
      flashOnBeat: defaultFlashOnBeat,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      keepDeviceAwake: json['keepDeviceAwake'] as bool? ?? defaultKeepDeviceAwake,
      saveEnergy: json['saveEnergy'] as bool? ?? defaultSaveEnergy,
      colorOnCorrectHex: json['colorOnCorrectHex'] as int? ?? defaultColorOnCorrectHex,
      tuningTolerance: (json['tuningTolerance'] as num? ?? defaultTuningTolerance).toDouble(),
      tickSound: TickSoundType.values.firstWhere(
        (e) => e.name == json['tickSound'],
        orElse: () => defaultTickSound,
      ),
      flashOnBeat: json['flashOnBeat'] as bool? ?? defaultFlashOnBeat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keepDeviceAwake': keepDeviceAwake,
      'saveEnergy': saveEnergy,
      'colorOnCorrectHex': colorOnCorrectHex,
      'tuningTolerance': tuningTolerance,
      'tickSound': tickSound.name, // Saves as a string key e.g., "classic"
      'flashOnBeat': flashOnBeat,
    };
  }

  AppSettings copyWith({
    bool? keepDeviceAwake,
    bool? saveEnergy,
    int? colorOnCorrectHex,
    double? tuningTolerance,
    TickSoundType? tickSound,
    bool? flashOnBeat,
  }) {
    return AppSettings(
      keepDeviceAwake: keepDeviceAwake ?? this.keepDeviceAwake,
      saveEnergy: saveEnergy ?? this.saveEnergy,
      colorOnCorrectHex: colorOnCorrectHex ?? this.colorOnCorrectHex,
      tuningTolerance: tuningTolerance ?? this.tuningTolerance,
      tickSound: tickSound ?? this.tickSound,
      flashOnBeat: flashOnBeat ?? this.flashOnBeat,
    );
  }
}