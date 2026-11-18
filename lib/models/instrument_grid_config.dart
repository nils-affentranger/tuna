class InstrumentGridConfig {
  final List<String> orderedIds;
  final Map<String, bool> visibilityMap;

  InstrumentGridConfig({
    required this.orderedIds,
    required this.visibilityMap,
  });

  factory InstrumentGridConfig.fromJson(Map<String, dynamic> json) {
    return InstrumentGridConfig(
      orderedIds: List<String>.from(json['orderedIds'] as List),
      visibilityMap: Map<String, bool>.from(json['visibilityMap'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {'orderedIds': orderedIds, 'visibilityMap': visibilityMap};
  }

  InstrumentGridConfig copyWith({
    List<String>? orderedIds,
    Map<String, bool>? visibilityMap,
  }) {
    return InstrumentGridConfig(
      orderedIds: orderedIds ?? this.orderedIds,
      visibilityMap: visibilityMap ?? this.visibilityMap,
    );
  }

  /// Keeps a saved order, drops unknown ids, and appends tunings added later.
  InstrumentGridConfig reconcile(Iterable<String> knownIds) {
    final known = knownIds.toSet();
    final ordered = <String>[
      for (final id in orderedIds)
        if (known.contains(id)) id,
    ];
    for (final id in knownIds) {
      if (!ordered.contains(id)) {
        ordered.add(id);
      }
    }
    return InstrumentGridConfig(
      orderedIds: ordered,
      visibilityMap: {
        for (final id in ordered) id: visibilityMap[id] ?? true,
      },
    );
  }
}
