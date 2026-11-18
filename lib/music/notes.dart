import 'dart:math';

const double a4Hz = 440;

double hzForMidi(int midi) => a4Hz * pow(2, (midi - 69) / 12);

double midiFromHz(double hz) => 69 + 12 * log(hz / a4Hz) / ln2;

double centsBetween(double hz, double targetHz) =>
    1200 * log(hz / targetHz) / ln2;

int beatIntervalMicros(double bpm) => (60000000 / bpm).round();

final _noteName = RegExp(r'^([A-Ga-g])([#b♯♭]?)(-?\d+)$');

const _semitones = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

const _chromaticNames = [
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

const _pitchLetters = [
  'C',
  'C',
  'D',
  'D',
  'E',
  'F',
  'F',
  'G',
  'G',
  'A',
  'A',
  'B',
];

const _pitchAccidentals = ['', '♯', '', '♯', '', '', '♯', '', '♯', '', '♯', ''];

class NoteName {
  final String letter;
  final String accidental;
  final int octave;
  final int midi;

  const NoteName({
    required this.letter,
    required this.accidental,
    required this.octave,
    required this.midi,
  });

  double get hz => hzForMidi(midi);

  String get semanticsLabel {
    final mark = accidental == '♯'
        ? '#'
        : accidental == '♭'
        ? 'b'
        : '';
    return '$letter$mark$octave';
  }
}

class PitchView {
  final String semanticsLabel;
  final String letter;
  final String accidental;
  final String octave;
  final double cents;
  final double targetHz;

  const PitchView({
    required this.semanticsLabel,
    required this.letter,
    required this.accidental,
    required this.octave,
    required this.cents,
    required this.targetHz,
  });

  static const silent = PitchView(
    semanticsLabel: '—',
    letter: '—',
    accidental: '',
    octave: '',
    cents: 0,
    targetHz: 0,
  );

  double get displayCents => cents.clamp(-50.0, 50.0);

  bool inTune({required bool hasSignal, required double tolerance}) =>
      hasSignal && targetHz > 0 && cents.isFinite && cents.abs() <= tolerance;
}

NoteName parseNoteName(String raw) {
  final match = _noteName.firstMatch(raw.trim());
  if (match == null) {
    throw FormatException('Expected a note name like E2 or F#4', raw);
  }
  final letter = match.group(1)!.toUpperCase();
  final accidental = _displayAccidental(match.group(2) ?? '');
  final octave = int.parse(match.group(3)!);
  var semi = _semitones[letter]!;
  if (accidental == '♯') {
    semi += 1;
  } else if (accidental == '♭') {
    semi -= 1;
  }
  return NoteName(
    letter: letter,
    accidental: accidental,
    octave: octave,
    midi: (octave + 1) * 12 + semi,
  );
}

PitchView chromaticPitch(double hz) {
  if (hz <= 0 || !hz.isFinite) {
    return PitchView.silent;
  }
  final nearestMidi = midiFromHz(hz).round().clamp(0, 127);
  final targetHz = hzForMidi(nearestMidi);
  final cents = centsBetween(hz, targetHz);
  final index = nearestMidi % 12;
  final octave = (nearestMidi ~/ 12) - 1;
  return PitchView(
    semanticsLabel: '${_chromaticNames[index]}$octave',
    letter: _pitchLetters[index],
    accidental: _pitchAccidentals[index],
    octave: '$octave',
    cents: cents,
    targetHz: targetHz,
  );
}

PitchView pitchAgainstNote(double hz, NoteName note) {
  if (hz <= 0 || !hz.isFinite) {
    return PitchView.silent;
  }
  return PitchView(
    semanticsLabel: note.semanticsLabel,
    letter: note.letter,
    accidental: note.accidental,
    octave: '${note.octave}',
    cents: centsBetween(hz, note.hz),
    targetHz: note.hz,
  );
}

String _displayAccidental(String token) {
  switch (token) {
    case '#':
    case '♯':
      return '♯';
    case 'b':
    case '♭':
      return '♭';
    default:
      return '';
  }
}
