import 'package:tuna/music/notes.dart';

class Instrument {
  final String id;
  final String name;
  final String iconPath;
  final List<InstrumentString> strings;

  Instrument({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.strings,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: json['id'] as String,
      name: json['name'] as String,
      iconPath: json['iconPath'] as String,
      strings: (json['strings'] as List<dynamic>)
          .map((item) => InstrumentString.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'strings': strings.map((s) => s.toJson()).toList(),
    };
  }

  Instrument copyWith({
    String? id,
    String? name,
    String? iconPath,
    List<InstrumentString>? strings,
  }) {
    return Instrument(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      strings: strings ?? this.strings,
    );
  }
}

class InstrumentString {
  final int index;
  final double note;
  final String label;

  InstrumentString({
    required this.index,
    required this.note,
    required this.label,
  });

  factory InstrumentString.fromJson(Map<String, dynamic> json) {
    final raw = json['note'];
    final NoteName parsed;
    if (raw is String) {
      parsed = parseNoteName(raw);
    } else if (raw is num) {
      final hz = raw.toDouble();
      final midi = midiFromHz(hz).round().clamp(0, 127);
      parsed = _noteNameFromMidi(midi);
    } else {
      throw FormatException('String note must be a name or frequency', raw);
    }
    return InstrumentString(
      index: json['index'] as int,
      note: parsed.hz,
      label: parsed.semanticsLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {'index': index, 'note': label};
  }

  InstrumentString copyWith({int? index, double? note, String? label}) {
    return InstrumentString(
      index: index ?? this.index,
      note: note ?? this.note,
      label: label ?? this.label,
    );
  }
}

NoteName _noteNameFromMidi(int midi) {
  const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  final octave = (midi ~/ 12) - 1;
  return parseNoteName('${names[midi % 12]}$octave');
}
