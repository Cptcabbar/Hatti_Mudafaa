import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Oyun genelinde ortak dekoratif arka plan: sıcak koyu degrade + hayalet
/// sektör-haritası tahtası + ufuk parıltısı + katmanlı siper silüeti (kırık
/// kazıklar, devrik tekerlek, sarkan tel) + çamurlu no man's land şeridi.
///
/// Ana menü ([HomeScreen]) ve tüm yükleme ekranları ([LoadingView]) bunu
/// kullanır — böylece uygulama açılıştan oyuna kadar tek bir görsel dilde kalır.
/// Tamamen statik `CustomPaint` (`shouldRepaint => false`), animasyonsuz —
/// yükleme ekranı hafif kalır. `docs/theme-bible.md`.
class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({super.key});

  /// Degradenin en koyu tonu — arka plan boyanmadan önce opak zemin için.
  static const Color base = AppPalette.base;

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
    if (w <= 0 || h <= 0) return;
    final rect = Offset.zero & size;
    final ridgeY = h * 0.66;

    // 1) Sıcak koyu degrade zemin.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C0A07), Color(0xFF13100A), Color(0xFF231B11)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // 2) Ufuk parıltısı — silüetleri arkadan aydınlatır (çok soluk amber).
    final glowRect = Rect.fromLTRB(0, ridgeY - h * 0.16, w, ridgeY + h * 0.04);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            AppPalette.amber.withValues(alpha: 0.085),
            const Color(0x00000000),
          ],
          stops: const [0.0, 0.72, 1.0],
        ).createShader(glowRect),
    );

    _sectorBoard(canvas, w, h);

    // 3) Katmanlı siper hattı (arkadan öne: soluk → koyu).
    canvas
      ..drawPath(_ridge(w, h, 0.66, h * 0.05, 7, 11),
          Paint()..color = const Color(0xFF241D12))
      ..drawPath(_ridge(w, h, 0.735, h * 0.045, 6, 7),
          Paint()..color = const Color(0xFF1A150D));
    _ridgeDebris(canvas, w, h);
    canvas.drawPath(_ridge(w, h, 0.83, h * 0.038, 6, 3),
        Paint()..color = const Color(0xFF110D07));

    _foreground(canvas, w, h);
    _hazards(canvas, w, h);
  }

  /// Jagged siper silüeti polygonu (y=h tabanına kapanır).
  Path _ridge(double w, double h, double baseFrac, double amp, int bumps,
      int seed) {
    final rnd = Random(seed);
    final baseY = h * baseFrac;
    final p = Path()
      ..moveTo(0, h)
      ..lineTo(0, baseY + (rnd.nextDouble() - 0.5) * amp);
    for (var i = 1; i <= bumps; i++) {
      p.lineTo(w * i / bumps, baseY + (rnd.nextDouble() - 0.42) * amp);
    }
    return p
      ..lineTo(w, h)
      ..close();
  }

  /// Orta sırtın üstündeki savaş enkazı silüeti: kırık kazıklar + eğik kiriş +
  /// devrik tekerlek + iki direk arası sarkan tel.
  void _ridgeDebris(Canvas canvas, double w, double h) {
    final rnd = Random(4021);
    final dark = Paint()..color = const Color(0xFF0E0B06);
    final line = Paint()
      ..color = const Color(0xFF0E0B06)
      ..strokeCap = StrokeCap.round;
    final rootY = h * 0.80;

    // Kırık kazık tarlası.
    for (var i = 0; i < 7; i++) {
      final x = w * (0.06 + 0.88 * rnd.nextDouble());
      final len = h * (0.024 + rnd.nextDouble() * 0.045);
      final lean = (rnd.nextDouble() - 0.5) * 0.7;
      line.strokeWidth = 1.3 + rnd.nextDouble() * 1.9;
      canvas.drawLine(
        Offset(x, rootY + rnd.nextDouble() * h * 0.02),
        Offset(x + sin(lean) * len, rootY - cos(lean) * len),
        line,
      );
    }

    // Eğik kiriş.
    line.strokeWidth = h * 0.01;
    canvas.drawLine(
      Offset(w * 0.17, rootY),
      Offset(w * 0.29, rootY - h * 0.058),
      line,
    );

    // Devrik top arabası tekerleği.
    final wheelC = Offset(w * 0.82, rootY - h * 0.008);
    final wheelR = h * 0.024;
    canvas.drawCircle(
      wheelC,
      wheelR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF0E0B06),
    );
    for (var k = 0; k < 6; k++) {
      final a = k * pi / 3;
      canvas.drawLine(wheelC,
          wheelC + Offset(cos(a) * wheelR, sin(a) * wheelR), line..strokeWidth = 1.4);
    }

    // İki direk + sarkan dikenli tel.
    final px0 = w * 0.42, px1 = w * 0.56;
    final topY = rootY - h * 0.045;
    canvas
      ..drawLine(Offset(px0, rootY), Offset(px0, topY), line..strokeWidth = 2.4)
      ..drawLine(Offset(px1, rootY), Offset(px1, topY - h * 0.006), line)
      ..drawPath(
        Path()
          ..moveTo(px0, topY)
          ..quadraticBezierTo(
              (px0 + px1) / 2, topY + h * 0.03, px1, topY - h * 0.006),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = const Color(0xFF141009),
      );
    // Çökmüş sığınak bloğu.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.63, rootY - h * 0.024, w * 0.08, h * 0.024),
        const Radius.circular(2),
      ),
      dark,
    );
  }

  /// Hayalet 7×7 sektör haritası: soluk ızgara + köşe köşebent işaretleri +
  /// üstte mavi / altta kırmızı kesikli hedef hattı + birkaç hayalet engel izi.
  void _sectorBoard(Canvas canvas, double w, double h) {
    final side = w * 0.62;
    final gx = (w - side) / 2;
    final gy = h * 0.11;
    final cell = side / 7;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var i = 0; i <= 7; i++) {
      canvas
        ..drawLine(Offset(gx + i * cell, gy), Offset(gx + i * cell, gy + side),
            grid)
        ..drawLine(Offset(gx, gy + i * cell), Offset(gx + side, gy + i * cell),
            grid);
    }

    // Köşe köşebentleri.
    final bracket = Paint()
      ..color = AppPalette.text.withValues(alpha: 0.22)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;
    const k = 14.0;
    for (final c in [
      Offset(gx, gy),
      Offset(gx + side, gy),
      Offset(gx, gy + side),
      Offset(gx + side, gy + side),
    ]) {
      final sx = c.dx == gx ? 1.0 : -1.0;
      final sy = c.dy == gy ? 1.0 : -1.0;
      canvas
        ..drawLine(c, c.translate(sx * k, 0), bracket)
        ..drawLine(c, c.translate(0, sy * k), bracket);
    }

    // Hedef hatları (kesikli).
    void dashed(double y, Color color) {
      final p = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2;
      for (var x = gx; x < gx + side; x += 14) {
        canvas.drawLine(Offset(x, y), Offset(min(x + 8, gx + side), y), p);
      }
    }

    dashed(gy + cell * 0.5, AppPalette.p1);
    dashed(gy + side - cell * 0.5, AppPalette.p2);

    // Hayalet engel izleri — kenarlara yakın, başlık metnini bulandırmasın.
    final scar = Paint()
      ..color = Colors.white.withValues(alpha: 0.032)
      ..strokeWidth = cell * 0.24
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(gx + cell * 1, gy + cell * 1),
          Offset(gx + cell * 2, gy + cell * 1), scar)
      ..drawLine(Offset(gx + cell * 6, gy + cell * 5),
          Offset(gx + cell * 6, gy + cell * 6), scar);
  }

  /// Ön plan: çamurlu no man's land şeridi + kraterler + moloz + tel yumakları.
  void _foreground(Canvas canvas, double w, double h) {
    final top = h * 0.84;
    final band = Rect.fromLTRB(0, top, w, h);
    canvas.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00140F09), Color(0xFF17120B)],
        ).createShader(band),
    );

    final rnd = Random(778);
    // Kraterler.
    for (var i = 0; i < 4; i++) {
      final cx = w * (0.1 + 0.8 * rnd.nextDouble());
      final cy = h * (0.87 + 0.1 * rnd.nextDouble());
      final r = w * (0.05 + 0.06 * rnd.nextDouble());
      canvas
        ..drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r),
          Paint()..color = const Color(0x33080503),
        )
        ..drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r),
          pi + 0.3,
          pi - 0.6,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0x1FCBB48A),
        );
    }

    // Moloz çubukları.
    final chunk = Paint()..color = const Color(0xCC0B0805);
    for (var i = 0; i < 14; i++) {
      canvas
        ..save()
        ..translate(w * rnd.nextDouble(), h * (0.86 + 0.13 * rnd.nextDouble()))
        ..rotate((rnd.nextDouble() - 0.5) * pi)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: 4 + rnd.nextDouble() * 12,
                height: 2.4),
            const Radius.circular(1),
          ),
          chunk,
        )
        ..restore();
    }

    // Dikenli tel yumakları.
    final wire = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x66120D08);
    for (var i = 0; i < 3; i++) {
      final cx = w * (0.15 + 0.7 * rnd.nextDouble());
      final cy = h * (0.9 + 0.06 * rnd.nextDouble());
      final rad = w * 0.03;
      for (var k = 0; k < 8; k++) {
        final a0 = rnd.nextDouble() * pi * 2;
        final a1 = a0 + 1 + rnd.nextDouble() * 2;
        canvas.drawLine(
          Offset(cx + cos(a0) * rad, cy + sin(a0) * rad * 0.5),
          Offset(cx + cos(a1) * rad * 1.2, cy + sin(a1) * rad * 0.6),
          wire,
        );
      }
    }
  }

  /// Serpiştirilmiş amber tehlike noktaları + birkaçında minik parıltı.
  void _hazards(Canvas canvas, double w, double h) {
    final rnd = Random(29);
    for (var i = 0; i < 7; i++) {
      final c = Offset(
        w * (0.08 + 0.84 * rnd.nextDouble()),
        h * (0.78 + 0.17 * rnd.nextDouble()),
      );
      if (i < 3) {
        canvas.drawCircle(
          c,
          6,
          Paint()
            ..shader = RadialGradient(
              colors: [
                AppPalette.amber.withValues(alpha: 0.4),
                AppPalette.amber.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: 6)),
        );
      }
      canvas.drawCircle(
        c,
        1.8,
        Paint()..color = AppPalette.amber.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
