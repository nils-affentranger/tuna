import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/services/app_controller.dart';
import 'package:tuna/services/metronome_engine.dart';
import 'package:tuna/widgets/top_bar.dart';
import 'package:tuna/widgets/tuna_scope.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  AppController? _app;
  Timer? _flashOff;
  bool _showFlash = false;
  int _seenFlash = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = TunaScope.of(context);
    if (!identical(app, _app)) {
      _app?.engine.removeListener(_onEngine);
      _app = app;
      app.engine.addListener(_onEngine);
      _seenFlash = app.engine.flashSerial;
    }
  }

  void _onEngine() {
    final app = _app;
    if (!mounted || app == null) {
      return;
    }
    final engine = app.engine;
    final shouldFlash =
        engine.flashSerial != _seenFlash &&
        app.settings.flashOnBeat &&
        !app.settings.saveEnergy;
    _seenFlash = engine.flashSerial;
    if (shouldFlash) {
      _showFlash = true;
      _flashOff?.cancel();
      _flashOff = Timer(const Duration(milliseconds: 220), () {
        if (!mounted) {
          return;
        }
        setState(() => _showFlash = false);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _app?.engine.removeListener(_onEngine);
    _flashOff?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    final engine = app.engine;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                TopBar(
                  title: 'Metronome',
                  buttonLeft: IconButton(
                    icon: const Icon(MynaSolid.music),
                    tooltip: 'Tuner',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  buttonRight: IconButton(
                    icon: const Icon(MynaSolid.cogTwo),
                    tooltip: 'Settings',
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
                const Spacer(),
                Text(
                  app.tempo.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${app.tempo.bpm.round()}',
                  style: TextStyle(
                    fontSize: 96,
                    height: 1,
                    fontWeight: FontWeight.w200,
                    color: _showFlash ? app.settings.colorOnCorrect : Colors.black,
                  ),
                ),
                const Text(
                  'bpm',
                  style: TextStyle(fontWeight: FontWeight.w300),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(MynaSolid.minus),
                        tooltip: 'Slower',
                        onPressed: () => app.bumpBpm(-1),
                      ),
                      Expanded(
                        child: Slider(
                          value: app.tempo.bpm.clamp(40, 240),
                          min: 40,
                          max: 240,
                          onChanged: app.setBpm,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(MynaSolid.plus),
                        tooltip: 'Faster',
                        onPressed: () => app.bumpBpm(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _BeatDots(app: app, engine: engine),
                const SizedBox(height: 20),
                _BeatCount(app: app),
                const Spacer(),
                Text(
                  engine.lastError ?? app.settings.tickSound.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: engine.lastError == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                _PlayButton(
                  playing: engine.playing,
                  onPressed: engine.toggle,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          if (_showFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: app.settings.colorOnCorrect.withValues(alpha: 0.28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BeatDots extends StatelessWidget {
  final AppController app;
  final MetronomeEngine engine;

  const _BeatDots({required this.app, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < app.beatsPerBar; i++)
          Container(
            width: i == 0 ? 18 : 14,
            height: i == 0 ? 18 : 14,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: engine.playing && engine.currentBeat == i
                  ? Colors.black
                  : Colors.transparent,
              border: Border.all(
                color: Colors.black,
                width: i == 0 ? 2 : 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _BeatCount extends StatelessWidget {
  final AppController app;

  const _BeatCount({required this.app});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final beats in [2, 3, 4, 5, 6])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CountChip(
              label: '$beats',
              selected: app.beatsPerBar == beats,
              onPressed: () => app.setBeatsPerBar(beats),
            ),
          ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _CountChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.transparent,
      shape: const CircleBorder(side: BorderSide(color: Colors.black)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onPressed;

  const _PlayButton({required this.playing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 84,
          height: 84,
          child: Icon(
            playing ? MynaSolid.pause : MynaSolid.play,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
