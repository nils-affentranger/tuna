import 'package:tuna/models/instrument.dart';
import 'package:tuna/music/notes.dart';

class StringMatch {
  final InstrumentString string;
  final PitchView pitch;

  const StringMatch({required this.string, required this.pitch});
}

StringMatch? nearestString(double hz, List<InstrumentString> strings) {
  if (hz <= 0 || !hz.isFinite || strings.isEmpty) {
    return null;
  }
  InstrumentString? best;
  var bestDistance = double.infinity;
  for (final string in strings) {
    final distance = centsBetween(hz, string.note).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = string;
    }
  }
  if (best == null) {
    return null;
  }
  return StringMatch(
    string: best,
    pitch: pitchAgainstNote(hz, parseNoteName(best.label)),
  );
}
