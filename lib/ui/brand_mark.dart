import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// Uygulama amblemi — "Cephe" teması (`docs/theme-bible.md`). Bir cephe hattının
/// (çentikli amber bar) iki yanında karşıt tarafların rütbe şevronları: üstte
/// soluk pas (Kırmızı) aşağı, altta soluk arduvaz (Mavi) yukarı bastırır. Oyunun
/// "iki taraf, bir hat" özünü tek glifte anlatır.
///
/// Uygulama ikonu, native açılış görseli ve (ileride) uygulama içi işaret için
/// **tek kaynak** — `test/tool/generate_brand_assets.dart` bunu PNG'lere basar.
///
/// [background] verilirse tuval önce onunla doldurulur (tam ikon); `null` ise
/// şeffaf kalır (adaptif ikon ön planı / açılış görseli). [inset] amblem
/// çevresindeki boşluk oranıdır — adaptif ikon güvenli alanı için ~0.16.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.background = AppPalette.base,
    this.inset = 0.06,
  });

  final Color? background;
  final double inset;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BrandPainter(background: background, inset: inset),
      );
}

class _BrandPainter extends CustomPainter {
  _BrandPainter({required this.background, required this.inset});

  final Color? background;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background!);
    }

    // Amblem, kısa kenara göre kare bir alana ortalanır.
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    final pad = s * inset.clamp(0.0, 0.4);
    final box = Rect.fromLTWH(pad, pad, s - 2 * pad, s - 2 * pad);
    final u = box.width; // amblem birim ölçüsü
    final cx = box.center.dx;
    final cy = box.center.dy;

    // --- Cephe hattı: kalın amber bar + soluk sektör çentikleri ---
    final half = u * 0.37;
    canvas.drawLine(
      Offset(cx - half, cy),
      Offset(cx + half, cy),
      Paint()
        ..color = AppPalette.amber
        ..strokeWidth = u * 0.055
        ..strokeCap = StrokeCap.round,
    );
    for (final f in const [-0.62, -0.21, 0.21, 0.62]) {
      final x = cx + half * f;
      canvas.drawLine(
        Offset(x, cy - u * 0.045),
        Offset(x, cy + u * 0.045),
        Paint()
          ..color = AppPalette.amberDim
          ..strokeWidth = u * 0.024
          ..strokeCap = StrokeCap.round,
      );
    }

    // --- Karşıt rütbe şevronları ---
    const w = 0.22; // yarım genişlik (u oranı)
    const drop = 0.12; // uç sarkması
    const gap = 0.15; // ucun bar merkezine mesafesi
    const rowGap = 0.11; // sıralar arası (barın uzağına doğru)
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void chevrons(Color color, int dir) {
      // dir = -1: üstte, aşağı bakan (Kırmızı) · dir = 1: altta, yukarı bakan.
      stroke.color = color;
      for (var r = 0; r < 2; r++) {
        final tipY = cy + dir * (gap + r * rowGap) * u;
        canvas.drawPath(
          Path()
            ..moveTo(cx - w * u, tipY + dir * drop * u)
            ..lineTo(cx, tipY)
            ..lineTo(cx + w * u, tipY + dir * drop * u),
          stroke,
        );
      }
    }

    chevrons(AppPalette.p2, -1);
    chevrons(AppPalette.p1, 1);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandPainter old) =>
      old.background != background || old.inset != inset;
}
