import 'package:flutter_test/flutter_test.dart';
import 'package:tuna/models/app_settings.dart';
import 'package:tuna/models/instrument.dart';
import 'package:tuna/models/instrument_grid_config.dart';
import 'package:tuna/models/tempo.dart';
import 'package:tuna/music/notes.dart';
import 'package:tuna/music/string_match.dart';

void main() {
  test('note names convert to equal-tempered frequencies', () {
    expect(parseNoteName('A4').hz, closeTo(440, 0.001));
    expect(parseNoteName('E2').hz, closeTo(82.4069, 0.001));
    expect(parseNoteName('F#4').hz, closeTo(369.994, 0.01));
    expect(parseNoteName('Bb3').midi, 58);
    expect(parseNoteName('g4').semanticsLabel, 'G4');
  });

  test('chromatic pitch names C4 and reports cents', () {
    final pitch = chromaticPitch(hzForMidi(60) * 1.01);
    expect(pitch.letter, 'C');
    expect(pitch.octave, '4');
    expect(pitch.cents, greaterThan(0));
    expect(pitch.inTune(hasSignal: true, tolerance: 1), isFalse);
    expect(chromaticPitch(0), PitchView.silent);
  });

  test('nearest guitar string prefers the closer target', () {
    final strings = [
      InstrumentString.fromJson(const {'index': 0, 'note': 'E2'}),
      InstrumentString.fromJson(const {'index': 1, 'note': 'A2'}),
      InstrumentString.fromJson(const {'index': 5, 'note': 'E4'}),
    ];
    expect(nearestString(110, strings)!.string.label, 'A2');
    expect(nearestString(440, strings)!.string.label, 'E4');
    final low = nearestString(82.41, strings)!;
    expect(low.string.index, 0);
    expect(low.pitch.inTune(hasSignal: true, tolerance: 5), isTrue);
    expect(nearestString(100, strings)!.string.label, 'A2');
  });

  test('120 bpm is half a second', () {
    expect(beatIntervalMicros(120), 500000);
    expect(tempoMarking(120), 'Allegro');
    expect(tempoMarking(90), 'Andante');
  });

  test('settings and tempo survive json', () {
    final settings = AppSettings.defaultSettings().copyWith(
      tickSound: TickSoundType.woodblock,
      tuningTolerance: 3.5,
      keepDeviceAwake: true,
      flashOnBeat: true,
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.tickSound, TickSoundType.woodblock);
    expect(restored.tuningTolerance, 3.5);
    expect(restored.keepDeviceAwake, isTrue);
    expect(restored.flashOnBeat, isTrue);

    final tempo = Tempo.fromJson(const {'id': 'current', 'name': 'Allegro', 'bpm': 132});
    expect(tempo.bpm, 132);
    expect(Tempo.fromJson(tempo.toJson()).name, 'Allegro');
  });

  test('grid keeps saved order and appends new tunings', () {
    final saved = <String, dynamic>{
      'orderedIds': ['gtr_standard', 'missing', 'uke_standard'],
      'visibilityMap': {'gtr_standard': false, 'uke_standard': true},
    };
    final grid = InstrumentGridConfig.fromJson(saved).reconcile(const [
      'uke_standard',
      'gtr_standard',
      'gtr_baritone',
    ]);
    expect(grid.orderedIds, ['gtr_standard', 'uke_standard', 'gtr_baritone']);
    expect(grid.visibilityMap['gtr_standard'], isFalse);
    expect(grid.visibilityMap['gtr_baritone'], isTrue);
  });
}
