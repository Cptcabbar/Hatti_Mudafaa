import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Oyun içi küçük simgeler — hem panel çipleri hem "Nasıl Oynanır" ekranı
/// kullanır. Hepsi `CustomPaint`; istenen renk + boyutta çizilir, tahtadaki
/// `_drawMine` / `_drawWire` diliyle uyumlu.

/// "Cephane" logosu — stilize topçu mermisi. Cephanelik puanı ve engel
/// maliyetleri bu simgeyle gösterilir (oyun içi para birimi).
class SupplyMark extends StatelessWidget {
  const SupplyMark({super.key, this.size = 13, this.color = AppPalette.amber});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _SupplyPainter(color)),
      );
}

class _SupplyPainter extends CustomPainter {
  const _SupplyPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bw = w * 0.54;
    final l = cx - bw / 2;
    final r = cx + bw / 2;
    final body = Paint()..color = color;
    // Mermi gövdesi: sivri ogiv uç + silindirik gövde + düz taban.
    canvas.drawPath(
      Path()
        ..moveTo(l, h * 0.40)
        ..quadraticBezierTo(l, h * 0.06, cx, h * 0.02)
        ..quadraticBezierTo(r, h * 0.06, r, h * 0.40)
        ..lineTo(r, h * 0.88)
        ..lineTo(l, h * 0.88)
        ..close(),
      body,
    );
    // Taban bileziği (biraz geniş).
    canvas.drawRect(Rect.fromLTRB(l - w * 0.10, h * 0.86, r + w * 0.10, h), body);
    // Sürücü bandı — koyu kesik.
    canvas.drawRect(
      Rect.fromLTRB(l, h * 0.58, r, h * 0.69),
      Paint()..color = const Color(0xFF201404).withValues(alpha: 0.38),
    );
  }

  @override
  bool shouldRepaint(covariant _SupplyPainter old) => old.color != color;
}

/// Mayın simgesi — üstten görünüş disk + tetik dikenleri + basınç halkası.
class MineMark extends StatelessWidget {
  const MineMark({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MinePainter(color)),
      );
}

class _MinePainter extends CustomPainter {
  const _MinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, size.height / 2);
    final rad = w * 0.30;
    // Tetik dikenleri — dışa taşan kısa çubuklar.
    final spike = Paint()
      ..color = color
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (rad * 0.85), c + d * (rad + w * 0.15), spike);
    }
    // Gövde (üstten görünüş) + basınç halkası + göbek.
    canvas
      ..drawCircle(c, rad, Paint()..color = color)
      ..drawCircle(
        c,
        rad * 0.58,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.06
          ..color = const Color(0xFF201404).withValues(alpha: 0.45),
      )
      ..drawCircle(c, w * 0.09, Paint()..color = const Color(0xFF201404));
  }

  @override
  bool shouldRepaint(covariant _MinePainter old) => old.color != color;
}

/// Dikenli tel simgesi — direkler + sarkan tel + dikenler.
class WireMark extends StatelessWidget {
  const WireMark({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _WirePainter(color)),
      );
}

class _WirePainter extends CustomPainter {
  const _WirePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.82;
    final topY = h * 0.28;
    final xs = [w * 0.15, w * 0.5, w * 0.85];
    final post = Paint()
      ..color = color
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    for (final x in xs) {
      canvas.drawLine(Offset(x, baseY), Offset(x, topY), post);
    }
    final wire = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055;
    for (final yf in const [0.40, 0.62]) {
      final y = h * yf;
      canvas.drawPath(
        Path()
          ..moveTo(xs.first, y)
          ..quadraticBezierTo(w * 0.5, y + h * 0.07, xs.last, y),
        wire,
      );
    }
    // Birkaç diken (X).
    final barb = Paint()
      ..color = color
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    for (final bx in [w * 0.33, w * 0.67]) {
      const by = 0.45;
      final p = Offset(bx, h * by);
      final s = w * 0.06;
      canvas
        ..drawLine(p + Offset(-s, -s), p + Offset(s, s), barb)
        ..drawLine(p + Offset(-s, s), p + Offset(s, -s), barb);
    }
  }

  @override
  bool shouldRepaint(covariant _WirePainter old) => old.color != color;
}
