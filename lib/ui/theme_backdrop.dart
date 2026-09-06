import 'dart:math';

import 'package:flutter/material.dart';

/// Oyun genelinde ortak dekoratif arka plan: sıcak koyu degrade + hayalet 7×7
/// tahta ızgarası + katmanlı low-poly siper hattı + serpiştirilmiş mayınlar.
///
/// Ana menü ([HomeScreen]) ve tüm yükleme ekranları ([LoadingView]) bunu
/// kullanır — böylece uygulama açılıştan oyuna kadar tek bir görsel dilde kalır.
/// `docs/theme-bible.md`.
class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({super.key});

  /// Degradenin en koyu tonu — arka plan boyanmadan önce opak zemin için.
  static const Color base = Color(0xFF0E0C08);

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _BackdropPainter(),
        size: Size.infinite,
        child: SizedBox.expand(),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Degrade zemin.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0C08), Color(0xFF15110A), Color(0xFF241D11)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Hayalet 7×7 tahta ızgarası (üst orta).
    final gridSide = w * 0.62;
    final gx = (w - gridSide) / 2;
    final gy = h * 0.11;
    final cell = gridSide / 7;
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var i = 0; i <= 7; i++) {
      canvas.drawLine(
        Offset(gx + i * cell, gy),
        Offset(gx + i * cell, gy + gridSide),
        grid,
      );
      canvas.drawLine(
        Offset(gx, gy + i * cell),
        Offset(gx + gridSide, gy + i * cell),
        grid,
      );
    }

    // Katmanlı low-poly siper hattı.
    void ridge(double baseY, double amp, Color color, int seed) {
      final rnd = Random(seed);
      final path = Path()..moveTo(0, h);
      path.lineTo(0, baseY + rnd.nextDouble() * amp);
      const steps = 8;
      for (var i = 1; i <= steps; i++) {
        path.lineTo(
          w * i / steps,
          baseY + (rnd.nextDouble() - 0.35) * amp,
        );
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    ridge(h * 0.72, 64, const Color(0xFF2A2416), 11);
    ridge(h * 0.81, 50, const Color(0xFF201B10), 7);
    ridge(h * 0.89, 34, const Color(0xFF17130B), 3);

    // Serpiştirilmiş mayınlar (küçük amber noktalar).
    final mine = Paint()..color = const Color(0xFFE0A72E).withValues(alpha: 0.45);
    final r = Random(29);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(w * (0.08 + 0.84 * r.nextDouble()),
            h * (0.80 + 0.13 * r.nextDouble())),
        2.2,
        mine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
