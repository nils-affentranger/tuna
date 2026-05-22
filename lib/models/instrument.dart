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
          .map((item) =>
          InstrumentString.fromJson(item as Map<String, dynamic>))
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

  InstrumentString({
    required this.index,
    required this.note,
  });

  factory InstrumentString.fromJson(Map<String, dynamic> json) {
    return InstrumentString(
      index: json['index'] as int,
      note: (json['note'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'note': note,
    };
  }

  InstrumentString copyWith({
    int? index,
    double? note,
  }) {
    return InstrumentString(
      index: index ?? this.index,
      note: note ?? this.note,
    );
  }
}