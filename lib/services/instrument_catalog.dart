import 'dart:convert';

import 'package:tuna/models/instrument.dart';

class CatalogEntry {
  final String familyId;
  final String familyName;
  final Instrument instrument;

  const CatalogEntry({
    required this.familyId,
    required this.familyName,
    required this.instrument,
  });

  String get id => instrument.id;
}

class InstrumentCatalog {
  final List<CatalogEntry> entries;

  const InstrumentCatalog(this.entries);

  static const empty = InstrumentCatalog([]);

  CatalogEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  static InstrumentCatalog parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Instrument catalog must be a JSON object');
    }
    final entries = <CatalogEntry>[];
    for (final family in decoded.entries) {
      final body = family.value;
      if (body is! Map) {
        continue;
      }
      final familyMap = Map<String, dynamic>.from(body);
      final iconPath = familyMap['iconPath'] as String? ?? '';
      final instruments = familyMap['instruments'];
      if (instruments is! List) {
        continue;
      }
      for (final raw in instruments) {
        if (raw is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(raw);
        final strings = (map['strings'] as List<dynamic>)
            .map(
              (item) => InstrumentString.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
        entries.add(
          CatalogEntry(
            familyId: family.key.toString(),
            familyName: familyLabel(family.key.toString()),
            instrument: Instrument(
              id: map['id'] as String,
              name: map['name'] as String,
              iconPath: iconPath,
              strings: strings,
            ),
          ),
        );
      }
    }
    return InstrumentCatalog(entries);
  }
}

String familyLabel(String key) {
  final words = key.split(RegExp(r'[_\s-]+')).where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
