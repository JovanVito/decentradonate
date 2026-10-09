import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Cincin riak: penanda progres bergaya tetesan air.
/// Semakin besar nilai, semakin penuh cincinnya.
class RippleRing extends StatelessWidget {
  final double percent; // 0..1
  final double size;
  final String? label;
  final Color color;
  final Color track;
  final Color inner;
  final TextStyle? labelStyle;

  const RippleRing({
    super.key,
    required this.percent,
    this.size = 54,
    this.label,
    this.color = AppColors.ripple,
    this.track = AppColors.paperDeep,
    this.inner = Colors.white,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RipplePainter(
              percent: clamped,
              color: color,
              track: track,
              inner: inner,
            ),
          ),
          Text(
            label ?? '${(clamped * 100).toStringAsFixed(0)}%',
            style: labelStyle ??
                TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color track;
  final Color inner;

  _RipplePainter({
    required this.percent,
    required this.color,
    required this.track,
    required this.inner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final stroke = size.width * 0.13;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius - stroke / 2, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      progressPaint,
    );

    final innerPaint = Paint()..color = inner;
    canvas.drawCircle(center, radius - stroke - size.width * 0.02, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.inner != inner;
}
