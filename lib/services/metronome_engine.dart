import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:tuna/models/app_settings.dart';
import 'package:tuna/music/notes.dart';

class MetronomeEngine extends ChangeNotifier {
  double Function()? _bpm;
  int Function()? _beatsPerBar;
  TickSoundType Function()? _tickSound;
  final Map<String, AudioPool> _pools = {};
  Timer? _timer;
  Stopwatch? _clock;
  int _nextUs = 0;

  bool playing = false;
  int currentBeat = 0;
  int beatIndex = 0;
  int flashSerial = 0;
  String? lastError;

  bool get lowLatency => !kIsWeb;

  void bind({
    required double Function() bpm,
    required int Function() beatsPerBar,
    required TickSoundType Function() tickSound,
  }) {
    _bpm = bpm;
    _beatsPerBar = beatsPerBar;
    _tickSound = tickSound;
  }

  void toggle() {
    if (playing) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    if (_bpm == null) {
      return;
    }
    playing = true;
    beatIndex = 0;
    currentBeat = 0;
    _clock = Stopwatch()..start();
    _nextUs = 0;
    _arm();
    notifyListeners();
  }

  void stop() {
    playing = false;
    _timer?.cancel();
    _timer = null;
    _clock?.stop();
    notifyListeners();
  }

  void retune() {
    final clock = _clock;
    if (!playing || clock == null) {
      return;
    }
    final beats = _beatsPerBar?.call() ?? 4;
    if (beatIndex >= beats) {
      beatIndex = 0;
    }
    _nextUs = clock.elapsedMicroseconds + _intervalUs();
    _arm();
  }

  Future<void> preview() => _play(accent: true);

  @override
  void dispose() {
    _timer?.cancel();
    final pools = _pools.values.toList();
    _pools.clear();
    for (final pool in pools) {
      unawaited(pool.dispose());
    }
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    final clock = _clock;
    if (!playing || clock == null) {
      return;
    }
    final intervalUs = _intervalUs();
    if (clock.elapsedMicroseconds + 800 >= _nextUs) {
      _fire();
      _nextUs += intervalUs;
      final now = clock.elapsedMicroseconds;
      if (_nextUs <= now) {
        _nextUs = now + intervalUs;
      }
    }
    final waitUs = math.max(2000, _nextUs - clock.elapsedMicroseconds);
    _timer = Timer(Duration(microseconds: waitUs), _arm);
  }

  void _fire() {
    final beats = _beatsPerBar?.call() ?? 4;
    final beat = beatIndex;
    beatIndex = beats <= 1 ? 0 : (beatIndex + 1) % beats;
    currentBeat = beat;
    flashSerial += 1;
    unawaited(_play(accent: beat == 0));
    notifyListeners();
  }

  int _intervalUs() {
    final bpm = _bpm?.call() ?? 120;
    return math.max(1, beatIntervalMicros(bpm));
  }

  Future<void> _play({required bool accent}) async {
    final sound = _tickSound?.call() ?? TickSoundType.classic;
    try {
      final pool = await _poolFor(sound, accent: accent);
      final stop = await pool.start();
      if (lowLatency) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 160), () {
            stop();
          }),
        );
      }
      if (lastError != null) {
        lastError = null;
        notifyListeners();
      }
    } catch (error) {
      lastError = 'Sound unavailable';
      notifyListeners();
    }
  }

  Future<AudioPool> _poolFor(TickSoundType sound, {required bool accent}) async {
    final key = '${sound.name}_${accent ? 'accent' : 'tick'}';
    final existing = _pools[key];
    if (existing != null) {
      return existing;
    }
    final pool = await AudioPool.create(
      source: AssetSource('ticks/$key.wav'),
      maxPlayers: 2,
      minPlayers: 1,
      playerMode: lowLatency ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
    );
    _pools[key] = pool;
    return pool;
  }
}
