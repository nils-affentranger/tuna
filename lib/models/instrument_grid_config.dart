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
    return {
      'orderedIds': orderedIds,
      'visibilityMap': visibilityMap,
    };
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
}