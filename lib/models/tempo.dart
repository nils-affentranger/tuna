String tempoMarking(double bpm) {
  if (bpm < 60) {
    return 'Largo';
  }
  if (bpm < 76) {
    return 'Adagio';
  }
  if (bpm < 108) {
    return 'Andante';
  }
  if (bpm < 120) {
    return 'Moderato';
  }
  if (bpm < 156) {
    return 'Allegro';
  }
  if (bpm < 176) {
    return 'Vivace';
  }
  return 'Presto';
}

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
      bpm: (json['bpm'] as num).toDouble(),
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