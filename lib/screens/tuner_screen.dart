import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/models/instrument.dart';
import 'package:tuna/music/notes.dart';
import 'package:tuna/music/string_match.dart';
import 'package:tuna/services/app_controller.dart';
import 'package:tuna/services/pitch_stream.dart';
import 'package:tuna/widgets/instrument_mark.dart';
import 'package:tuna/widgets/top_bar.dart';
import 'package:tuna/widgets/tuna_scope.dart';
import 'package:tuna/widgets/tuner_gauge.dart';

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
  DateTime _lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
  late AppController _app;

  @override
  void initState() {
    super.initState();
    if (!PitchStream.isSupported) {
      return;
    }
    _pitchSubscription = _pitchStream.listen().listen(
      _onPitch,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = TunaScope.of(context);
  }

  void _onPitch(PitchReading reading) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final gated = _app.settings.saveEnergy;
    final elapsed = now.difference(_lastPaint).inMilliseconds;
    final signalChanged = reading.hasPitch != _reading.hasPitch;
    if (gated && elapsed < 125 && !signalChanged) {
      return;
    }
    _lastPaint = now;
    setState(() {
      _reading = reading;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _pitchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    final instrument = app.selectedInstrument;
    final hasSignal = _reading.hz > 0 && _reading.clarity >= 0.5;
    final PitchView pitch;
    final StringMatch? match;
    if (instrument == null) {
      match = null;
      pitch = chromaticPitch(_reading.hz);
    } else if (hasSignal) {
      match = nearestString(_reading.hz, instrument.instrument.strings);
      pitch = match?.pitch ?? PitchView.silent;
    } else {
      match = null;
      pitch = PitchView.silent;
    }
    final inTune = pitch.inTune(
      hasSignal: hasSignal,
      tolerance: app.settings.tuningTolerance,
    );
    final noteColor = inTune ? app.settings.colorOnCorrect : Colors.black;
    final statusText = _statusText(app, instrument?.familyName, match, hasSignal);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Tuner',
              buttonLeft: IconButton(
                icon: const Icon(MynaSolid.activity),
                tooltip: 'Metronome',
                onPressed: () => Navigator.pushNamed(context, '/metronome'),
              ),
              buttonRight: IconButton(
                icon: const Icon(MynaSolid.cogTwo),
                tooltip: 'Settings',
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            _InstrumentButton(
              label: instrument == null
                  ? 'Chromatic'
                  : '${instrument.familyName} · ${instrument.instrument.name}',
              familyId: instrument?.familyId,
              onPressed: app.isReady
                  ? () => Navigator.pushNamed(context, '/instruments')
                  : null,
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  child: TunerGauge(
                    cents: hasSignal ? pitch.displayCents : 0,
                    letter: pitch.letter,
                    accidental: pitch.accidental,
                    octave: pitch.octave,
                    semanticsLabel: pitch.semanticsLabel,
                    hz: hasSignal ? _reading.hz : 0,
                    noteColor: noteColor,
                  ),
                ),
              ),
            ),
            if (instrument != null)
              _StringRow(
                strings: instrument.instrument.strings,
                activeIndex: match?.string.index,
                inTune: inTune,
                color: app.settings.colorOnCorrect,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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

  String _statusText(
    AppController app,
    String? familyName,
    StringMatch? match,
    bool hasSignal,
  ) {
    if (_errorMessage != null) {
      return _errorMessage!;
    }
    if (!PitchStream.isSupported) {
      return 'Microphone tuning runs on Android';
    }
    if (!hasSignal) {
      return 'Listening for a stable pitch';
    }
    final clarity = '${(_reading.clarity * 100).round()}% clarity';
    if (match == null || familyName == null) {
      return 'Mic input · $clarity';
    }
    return '$familyName · ${match.string.label} · $clarity';
  }
}

class _InstrumentButton extends StatelessWidget {
  final String label;
  final String? familyId;
  final VoidCallback? onPressed;

  const _InstrumentButton({
    required this.label,
    required this.familyId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (familyId == null)
              const Icon(MynaSolid.music, size: 18)
            else
              InstrumentMark(familyId: familyId!),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StringRow extends StatelessWidget {
  final List<InstrumentString> strings;
  final int? activeIndex;
  final bool inTune;
  final Color color;

  const _StringRow({
    required this.strings,
    required this.activeIndex,
    required this.inTune,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: strings.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final string = strings[index];
          final active = string.index == activeIndex;
          final filled = active && inTune;
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: filled ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? (filled ? color : Colors.black) : Colors.black26,
                width: active ? 1.6 : 1,
              ),
            ),
            child: Text(
              string.label,
              style: TextStyle(
                color: filled ? Colors.white : Colors.black,
                fontWeight: active ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          );
        },
      ),
    );
  }
}
