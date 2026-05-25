import 'dart:async';

import 'package:flutter/services.dart';

class PitchReading {
  final double hz;
  final double clarity;

  const PitchReading({required this.hz, required this.clarity});

  factory PitchReading.fromEvent(Object? event) {
    final values = Map<Object?, Object?>.from(event as Map<Object?, Object?>);
    return PitchReading(
      hz: (values['hz'] as num?)?.toDouble() ?? 0,
      clarity: (values['clarity'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get hasPitch => hz > 0 && clarity > 0;
}

class PitchStream {
  static const EventChannel _channel = EventChannel('tuna/pitch_stream');

  Stream<PitchReading> listen() =>
      _channel.receiveBroadcastStream().map(PitchReading.fromEvent);
}
