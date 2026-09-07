import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_theme.dart';

/// Ekranın üstüne yavaşça düşen kül + titreşen kor zerreleri — oyun içindeki
/// `BoardComponent._drawAshOverlay` efektinin menü / karşılama karşılığı.
///
/// Kendi [Ticker]'ıyla döner (widget ağacı yeniden kurulmaz, yalnızca boya
/// yenilenir); işaretçi olaylarını yutmaz. Menü başka bir rota ile örtülünce
/// `TickerMode` ile otomatik durur. "Partiküller" ayarını çağıran gate'ler
/// (bkz. [HomeScreen]) — kapalıyken bu widget hiç kurulmaz.
class AshFall extends StatefulWidget {
  const AshFall({super.key, this.motes = 26, this.horizonGlow = true});

  /// Kaç kül zerresi düşer (her 5'te biri kor).
  final int motes;

  /// Ufuk çizgisinde bağımsız nabız atan iki uzak yangın parıltısı.
  final bool horizonGlow;

  @override
  State<AshFall> createState() => _AshFallState();
}

class _AshFallState extends State<AshFall>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  late final List<_Ash> _ash = _seed(widget.motes);

  /// Oyun içindeki `_ensureAsh` ile aynı dağılım (aynı seed → aynı his).
  static List<_Ash> _seed(int n) {
    final rnd = Random(90190);
    return [
      for (var i = 0; i < n; i++)
        if (i % 5 == 0)
          _Ash(
            nx: rnd.nextDouble(),
            ny: rnd.nextDouble(),
            r: 2.0 + rnd.nextDouble() * 2.4,
            spd: 7 + rnd.nextDouble() * 15,
            amp: 6 + rnd.nextDouble() * 18,
            phase: rnd.nextDouble() * pi * 2,
            a: 0.30 + rnd.nextDouble() * 0.16,
            ember: true,
          )
        else
          _Ash(
            nx: rnd.nextDouble(),
            ny: rnd.nextDouble(),
            r: 1.2 + rnd.nextDouble() * 2.8,
            spd: 7 + rnd.nextDouble() * 15,
            amp: 6 + rnd.nextDouble() * 18,
            phase: rnd.nextDouble() * pi * 2,
            a: 0.16 + rnd.nextDouble() * 0.14,
            ember: false,
          ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _t.value = elapsed.inMicroseconds / 1e6;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AshPainter(_t, _ash, horizonGlow: widget.horizonGlow),
          size: Size.infinite,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AshPainter extends CustomPainter {
  _AshPainter(this.time, this.ash, {required this.horizonGlow})
      : super(repaint: time);

  /// Monoton artan saniye sayacı ([Ticker] geçen süresi).
  final ValueListenable<double> time;
  final List<_Ash> ash;
  final bool horizonGlow;

  /// `theme_backdrop.dart` ile aynı ufuk oranı — parıltılar sırtın üstüne otursun.
  static const double _ridgeFrac = 0.66;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = time.value;

    // Ufuk çizgisinde iki uzak yangın — bağımsız, yavaş nabız (arkadan sıcaklık).
    if (horizonGlow) {
      for (var i = 0; i < 2; i++) {
        final gx = w * (i == 0 ? 0.30 : 0.75);
        final gy = h * (_ridgeFrac - 0.015);
        final pulse = 0.5 + 0.5 * sin(t * (0.5 + i * 0.22) + i * 2.3);
        final rad = h * 0.055 * (0.8 + 0.35 * pulse);
        canvas.drawCircle(
          Offset(gx, gy),
          rad,
          Paint()
            ..shader = RadialGradient(
              colors: [
                AppPalette.amber.withValues(alpha: 0.08 + 0.09 * pulse),
                AppPalette.amber.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: Offset(gx, gy), radius: rad)),
        );
      }
    }

    // Düşen kül + kor — oyun içindeki _drawAshOverlay ile birebir hareket.
    final cycle = h + 40;
    final dot = Paint();
    for (final a in ash) {
      final yy = (((a.ny * cycle + t * a.spd) % cycle) + cycle) % cycle - 20;
      final xx = a.nx * w +
          sin(t * 0.6 + a.phase) * a.amp +
          sin(t * 1.7 + a.phase * 2) * a.amp * 0.3;
      if (a.ember) {
        final gl = 0.5 + 0.5 * sin(t * 5 + a.phase);
        final r = a.r * (1.9 + 0.6 * gl);
        canvas.drawCircle(
          Offset(xx, yy),
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.fromRGBO(244, 150, 66, a.a * (0.42 + 0.5 * gl)),
                const Color(0x00F49642),
              ],
            ).createShader(Rect.fromCircle(center: Offset(xx, yy), radius: r)),
        );
      } else {
        dot.color = Color.fromRGBO(166, 156, 136, a.a);
        canvas.drawCircle(Offset(xx, yy), a.r, dot);
      }
    }
  }

  // Boya, [time] listenable'ı ile yenilenir; parametre kıyası gereksiz.
  @override
  bool shouldRepaint(covariant _AshPainter oldDelegate) => false;
}

/// Havada süzülen tek bir kül / kor zerresi (ekran uzayı, normalize başlangıç).
class _Ash {
  const _Ash({
    required this.nx,
    required this.ny,
    required this.r,
    required this.spd,
    required this.amp,
    required this.phase,
    required this.a,
    required this.ember,
  });

  /// Normalize başlangıç konumu (0..1 viewport).
  final double nx;
  final double ny;

  /// Yarıçap (px), düşme hızı (px/sn), yanal salınım genliği (px), faz, alfa.
  final double r;
  final double spd;
  final double amp;
  final double phase;
  final double a;

  /// `true` ise titreşen turuncu kor, değilse gri kül.
  final bool ember;
}
