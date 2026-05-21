class Tempo {
  final String id;
  final String name;
  final double bpm;

  Tempo({
    required this.id,
    required this.name,
    required this.bpm,
  });

  factory Tempo.fromJson(Map<String, dynamic> json) {
    return Tempo(
      id: json['id'] as String,
      name: json['name'] as String,
      bpm: (json['double'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bpm': bpm,
    };
  }

  Tempo copyWith({
    String? id,
    String? name,
    double? bpm,
  }) {
    return Tempo(
      id: id ?? this.id,
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
    );
  }
}