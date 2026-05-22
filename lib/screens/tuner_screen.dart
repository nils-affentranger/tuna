import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuna/widgets/top_bar.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/widgets/tuner_gauge.dart';

/// A4 = 440 Hz equal temperament.
const double _a4Hz = 440;

/// MIDI note number (float) for a frequency.
double _midiFromHz(double hz) => 69 + 12 * log(hz / _a4Hz) / ln2;

/// Tempered frequency for an integer MIDI note (A4 = 69).
double _hzForMidi(int midi) => _a4Hz * pow(2, (midi - 69) / 12);

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

/// Stem glyph for tuner display (paired with `_pitchAccidentals`).
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

/// `♯` or empty natural; aligns with `_pitchLetters` indexing.
const _pitchAccidentals = ['', '♯', '', '♯', '', '', '♯', '', '♯', '', '♯', ''];

/// Nearest tempered pitch and gauge labels (needle clamped to the demo arc).
({String semanticsLabel, String letter, String accidental, double cents})
_pitchFromHz(double hz) {
  if (hz <= 0) {
    return (semanticsLabel: '—', letter: '—', accidental: '', cents: 0);
  }
  final nearestMidi = _midiFromHz(hz).round().clamp(0, 127);
  final targetHz = _hzForMidi(nearestMidi);
  var cents = 1200 * log(hz / targetHz) / ln2;
  cents = cents.clamp(-50.0, 50.0);
  final i = nearestMidi % 12;
  return (
    semanticsLabel: _chromaticNames[i],
    letter: _pitchLetters[i],
    accidental: _pitchAccidentals[i],
    cents: cents,
  );
}

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  static final double _hzC4 = _hzForMidi(60);
  static final double _hzC5 = _hzForMidi(72);

  /// UI-test only: C4–C5 range, note + cents from nearest tempered pitch.
  double _testHz = _a4Hz;

  @override
  Widget build(BuildContext context) {
    final detected = _pitchFromHz(_testHz);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Tuner',
              buttonRight: IconButton(
                icon: const Icon(MynaSolid.cogTwo),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
            Expanded(
              child: Center(
                child: TunerGauge(
                  cents: detected.cents,
                  letter: detected.letter,
                  accidental: detected.accidental,
                  semanticsLabel: detected.semanticsLabel,
                  hz: _testHz,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Test frequency (slider)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Slider(
                    value: _testHz,
                    min: _hzC4,
                    max: _hzC5,
                    label:
                        '${detected.semanticsLabel} · ${_testHz.toStringAsFixed(2)} Hz',
                    onChanged: (v) => setState(() => _testHz = v),
                  ),
                  Text(
                    'Nearest equal-tempered note (440 Hz A4). Needle clamped to ±50¢.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
