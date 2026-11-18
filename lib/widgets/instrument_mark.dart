import 'dart:math';

import 'package:flutter/material.dart';

class InstrumentMark extends StatelessWidget {
  final String familyId;

  const InstrumentMark({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _InstrumentMarkPainter(familyId: familyId),
    );
  }
}

class _InstrumentMarkPainter extends CustomPainter {
  final String familyId;

  _InstrumentMarkPainter({required this.familyId});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final ukulele = familyId == 'ukulele';
    final neckTop = ukulele ? size.height * 0.18 : size.height * 0.04;
    final neckBottom = ukulele ? size.height * 0.48 : size.height * 0.46;
    final neckWidth = ukulele ? size.width * 0.12 : size.width * 0.1;
    final bodyCenter = Offset(size.width / 2, ukulele ? size.height * 0.68 : size.height * 0.7);
    final bodyRadius = ukulele ? size.width * 0.28 : size.width * 0.32;

    canvas.drawLine(
      Offset(size.width / 2, neckTop),
      Offset(size.width / 2, neckBottom),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2 - neckWidth, neckTop + 2),
      Offset(size.width / 2 + neckWidth, neckTop + 2),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter,
        width: bodyRadius * (ukulele ? 1.7 : 1.85),
        height: bodyRadius * (ukulele ? 1.9 : 2.15),
      ),
      paint,
    );
    canvas.drawCircle(bodyCenter, ukulele ? 3.2 : 3.6, paint);
    if (!ukulele) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(bodyCenter.dx, bodyCenter.dy + bodyRadius * 0.55),
          width: bodyRadius,
          height: bodyRadius * 0.55,
        ),
        pi * 1.05,
        pi * 0.9,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InstrumentMarkPainter oldDelegate) =>
      oldDelegate.familyId != familyId;
}
