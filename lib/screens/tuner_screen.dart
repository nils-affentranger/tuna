import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/services/pitch_stream.dart';
import 'package:tuna/widgets/tuner_gauge.dart';
import 'package:tuna/widgets/top_bar.dart';

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
  final PitchStream _pitchStream = PitchStream();
  StreamSubscription<PitchReading>? _pitchSubscription;
  PitchReading _reading = const PitchReading(hz: 0, clarity: 0);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pitchSubscription = _pitchStream.listen().listen(
      (reading) {
        if (!mounted) {
          return;
        }
        setState(() {
          _reading = reading;
          _errorMessage = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _reading = const PitchReading(hz: 0, clarity: 0);
          _errorMessage = 'Microphone unavailable';
        });
      },
    );
  }

  @override
  void dispose() {
    _pitchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detected = _pitchFromHz(_reading.hz);
    final statusText =
        _errorMessage ??
        (_reading.hasPitch
            ? 'Mic input · ${(_reading.clarity * 100).round()}% clarity'
            : 'Listening for a stable pitch');

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
                  hz: _reading.hz,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _errorMessage == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
