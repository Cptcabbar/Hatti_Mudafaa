import 'dart:math';

import 'package:flutter/material.dart';

import 'theme_backdrop.dart';

/// Oyunun **tüm** yükleme ekranları için ortak görünüm.
///
/// Ana menüyle aynı arka plan ([ThemeBackdrop]) + temaya uygun bir radar
/// tarama animasyonu + küçük "Yükleniyor" yazısı. Uygulama açılışı, Flame
/// sahnesinin hazırlanması ve ileride online lobi / yapay zeka hazırlığı gibi
/// her async bekleme noktası bunu gösterir.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Yükleniyor'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ThemeBackdrop.base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ThemeBackdrop(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _RadarSpinner(),
                  const SizedBox(height: 22),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: Color(0xFFB7AE97),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber radar taraması: sabit menzil halkaları + dönen tarama kaması.
/// Askeri temaya uygun, "çalışıyor" hissini tek bakışta verir.
class _RadarSpinner extends StatefulWidget {
  const _RadarSpinner();

  @override
  State<_RadarSpinner> createState() => _RadarSpinnerState();
}

class _RadarSpinnerState extends State<_RadarSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(painter: _RadarPainter(_controller.value)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.t);

  /// 0..1 döngü ilerlemesi.
  final double t;

  static const Color _amber = Color(0xFFE0A72E);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Menzil halkaları + artı nişangah.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _amber.withValues(alpha: 0.28);
    for (final f in const [0.42, 0.72, 1.0]) {
      canvas.drawCircle(center, radius * f, ring);
    }
    final cross = Paint()
      ..strokeWidth = 1
      ..color = _amber.withValues(alpha: 0.16);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      cross,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      cross,
    );

    // Dönen tarama kaması (arkasında sönen iz).
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * pi);
    final sweepRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          _amber.withValues(alpha: 0),
          _amber.withValues(alpha: 0.35),
        ],
        stops: const [0.72, 1.0],
      ).createShader(sweepRect);
    canvas.drawCircle(Offset.zero, radius, sweep);
    // Tarama çizgisinin ön kenarı.
    canvas.drawLine(
      Offset.zero,
      Offset(radius, 0),
      Paint()
        ..strokeWidth = 1.5
        ..color = _amber.withValues(alpha: 0.85),
    );
    canvas.restore();

    // Merkez nokta.
    canvas.drawCircle(center, 2, Paint()..color = _amber.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.t != t;
}
