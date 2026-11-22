import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/wave_theme.dart';

/// Layered aqua waves reminiscent of the WAVE home reference.
/// Drawn natively so the result scales to any phone aspect ratio.
class WaveBackground extends StatelessWidget {
  final Widget child;
  const WaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FFFF), Color(0xFFDDFCFC), Color(0xFFC4F8FA)],
          ),
        ),
      ),
      CustomPaint(painter: _WavePainter()),
      child,
    ],
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final upper =
        Path()
          ..moveTo(0, h * .19)
          ..cubicTo(w * .38, h * .27, w * .64, h * .04, w, h * .06)
          ..lineTo(w, 0)
          ..lineTo(0, 0)
          ..close();
    canvas.drawPath(
      upper,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x338AF1EF), Color(0x8875EDEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h * .3)),
    );
    final stripe =
        Path()
          ..moveTo(0, h * .28)
          ..cubicTo(w * .48, h * .27, w * .56, h * .09, w, h * .14)
          ..lineTo(w, h * .19)
          ..cubicTo(w * .56, h * .17, w * .45, h * .37, 0, h * .31)
          ..close();
    canvas.drawPath(stripe, Paint()..color = const Color(0x5570EBEE));
    final bottom1 =
        Path()
          ..moveTo(0, h * .83)
          ..cubicTo(w * .22, h * .79, w * .36, h * .98, w * .66, h * .89)
          ..cubicTo(w * .82, h * .83, w * .92, h * .84, w, h * .8)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
    canvas.drawPath(
      bottom1,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x7798FFFF), Color(0x66A0F1F1), Color(0x9958DED9)],
        ).createShader(Rect.fromLTWH(0, h * .79, w, h * .21)),
    );
    final bottom2 =
        Path()
          ..moveTo(0, h * .93)
          ..cubicTo(w * .32, h * .97, w * .51, h * .89, w * .72, h * .94)
          ..quadraticBezierTo(w * .88, h * .96, w, h * .91)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
    canvas.drawPath(
      bottom2,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x9970F3F1), Color(0x5530CDC9)],
        ).createShader(Rect.fromLTWH(0, h * .90, w, h * .10)),
    );
    final glowCenter = Offset(w * .88, h * .36);
    canvas.drawCircle(
      glowCenter,
      math.min(w, h) * .47,
      Paint()
        ..shader = RadialGradient(
          colors: [
            WaveColors.turquoise.withValues(alpha: .16),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: math.min(w, h) * .47),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
