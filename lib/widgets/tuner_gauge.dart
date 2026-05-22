import 'dart:math';

import 'package:flutter/material.dart';

class _BottomCenteredNote extends StatelessWidget {
  final String letter;
  final String accidental;
  final TextStyle style;

  const _BottomCenteredNote({
    required this.letter,
    required this.accidental,
    required this.style,
  });

  static const double _gaugeContentWidth = 320;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style.copyWith(height: 1.0);
    final accStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 100) * 0.45,
      color: Colors.black54,
    );

    final letterPainter = TextPainter(
      text: TextSpan(text: letter, style: baseStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    final lw = letterPainter.width;
    final lh = letterPainter.height;
    final letterLeft = (_gaugeContentWidth - lw) / 2;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: _gaugeContentWidth,
        height: lh,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: letterLeft,
              bottom: 0,
              child: Text(letter, style: baseStyle),
            ),
            Positioned(
              left: letterLeft + lw,
              bottom: lh * 0.65,
              child: Text(accidental, style: accStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class TunerGauge extends StatelessWidget {
  final double cents;
  final String letter;
  final String accidental;

  /// Screen reader / semantics string (e.g. `C#`).
  final String semanticsLabel;

  /// Frequency to show below the gauge (e.g. from mic or a UI test slider).
  final double hz;

  const TunerGauge({
    super.key,
    required this.cents,
    required this.letter,
    required this.accidental,
    required this.semanticsLabel,
    this.hz = 440,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(320, 185),
          painter: _TunerPainter(cents),
          child: Container(
            height: 160,
            alignment: Alignment.bottomCenter,
            child: Semantics(
              label: semanticsLabel,
              child: _BottomCenteredNote(
                letter: letter,
                accidental: accidental,
                style:
                    Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 100,
                      height: 1.0,
                      fontWeight: FontWeight.w200,
                      color: Colors.black,
                    ) ??
                    const TextStyle(
                      fontSize: 100,
                      height: 1.0,
                      fontWeight: FontWeight.w200,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              hz >= 100 ? hz.toStringAsFixed(1) : hz.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              "hz",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TunerPainter extends CustomPainter {
  final double cents;
  _TunerPainter(this.cents);

  @override
  void paint(Canvas canvas, Size size) {
    // Offset slightly higher to keep gauge elements prominent
    const double verticalOffset = 20;
    final center = Offset(size.width / 2, size.height - verticalOffset);
    final double radius = size.height * 0.8;
    const double sweepAngle = pi * 0.85;

    final Paint tickPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.square; // Maintained sharp/square ends

    // Proximity parameters
    const double influenceRange =
        15.0; // The range of cents that will trigger thick ticks

    for (int i = -50; i <= 50; i += 2) {
      final double angle = (pi * 1.5) + (i * (sweepAngle) / 100);
      final bool isMajor = i % 10 == 0;
      final double tickLength = isMajor ? 10 : 5;

      // Calculate how close the needle is to this specific tick (in cents)
      final double distance = (cents - i).abs();

      // Calculate a scale factor between 0.0 (far away) and 1.0 (exact match)
      final double proximityFactor = (1.0 - (distance / influenceRange)).clamp(
        0.0,
        1.0,
      );

      // Define base stroke width and maximum scaled stroke width
      final double baseWidth = isMajor ? 1.5 : 1.0;
      final double maxAdditionalWidth = isMajor ? 2.5 : 1.5;

      // Interpolate the stroke width based on proximity to the needle
      tickPaint.strokeWidth =
          baseWidth + (maxAdditionalWidth * proximityFactor);

      canvas.drawLine(
        Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        ),
        Offset(
          center.dx + (radius + tickLength) * cos(angle),
          center.dy + (radius + tickLength) * sin(angle),
        ),
        tickPaint,
      );

      if (isMajor) {
        _drawRotatedText(canvas, center, radius + tickLength + 8, angle, "$i");
      }
    }

    // GRADIENT NEEDLE
    final double needleAngle = (pi * 1.5) + (cents * (sweepAngle) / 100);
    final Offset nStart = center;
    final Offset nEnd = Offset(
      center.dx + (radius + 8) * cos(needleAngle),
      center.dy + (radius + 8) * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..strokeWidth =
          2.0 // Slightly thicker needle to match the dynamic ticks
      ..strokeCap = StrokeCap.square
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [Colors.transparent, Colors.black],
        stops: const [0.2, 1],
      ).createShader(Rect.fromPoints(nStart, nEnd));

    canvas.drawLine(nStart, nEnd, needlePaint);
  }

  void _drawRotatedText(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    canvas.save();
    canvas.translate(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    canvas.rotate(angle + (pi / 2));
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TunerPainter oldDelegate) =>
      oldDelegate.cents != cents;
}
