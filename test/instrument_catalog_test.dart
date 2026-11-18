import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuna/services/instrument_catalog.dart';

void main() {
  test('bundled catalog has guitar and ukulele tunings', () {
    final catalog = InstrumentCatalog.parse(
      File('assets/instruments.json').readAsStringSync(),
    );
    expect(catalog.entries, hasLength(9));
    final standard = catalog.byId('gtr_standard')!;
    expect(standard.familyName, 'Guitar');
    expect(standard.instrument.strings.first.label, 'E2');
    expect(standard.instrument.strings.first.note, closeTo(82.4069, 0.01));
    expect(catalog.byId('uke_hawaiian')!.instrument.strings[2].label, 'F#4');
    expect(familyLabel('ukulele'), 'Ukulele');
  });
}
