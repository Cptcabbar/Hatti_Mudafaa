import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:game_core/game_core.dart';

import 'board_metrics.dart';
import 'board_projection.dart';
import 'game_controller.dart';

/// Yerel oyunun Flame sahnesi. Şimdilik her kare durumdan yeniden çizilir;
/// Faz 2'de piyon/engel ayrı animasyonlu bileşenlere ayrılacak.
class HattiBoardGame extends FlameGame {
  HattiBoardGame(this.controller);

  final GameController controller;
  late final BoardComponent board;

  @override
  Color backgroundColor() => const Color(0xFF14110D);

  @override
  Future<void> onLoad() async {
    board = BoardComponent(controller);
    add(board);
  }
}

class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent(this.controller);

  final GameController controller;

  BoardMetrics? _metrics;
  BoardProjection? _projection;

  /// Bir kez üretilen sert zemin dokusu (çamur + benek + krater + ızgara +
  /// hedef sektörleri). Eğim izdüşümüyle her kare projeksiyondan geçirilir.
  Image? _groundImage;

  /// Tahtanın çizim alanındaki sol-üst köşesi (viewport pikseli).
  Offset _origin = Offset.zero;
  double _boardSide = 0;

  /// -1..1 eğim; sıra değişince [update] içinde hedefe doğru animasyonlanır.
  double _tilt = 0;

  BoardMetrics? get metrics => _metrics;

  double get _targetTilt {
    if (controller.isOver) return 0;
    return controller.turn == Player.p1 ? 1.0 : -1.0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();

    _boardSide = math.min(size.x * 1.02, size.y * 0.88);
    _metrics = BoardMetrics(
      boardSize: controller.state.config.boardSize,
      side: _boardSide,
    );
    _bakeGround();
    _rebuildProjection();
  }

  @override
  void onRemove() {
    _groundImage?.dispose();
    _groundImage = null;
    super.onRemove();
  }

  void _rebuildProjection() {
    if (_boardSide <= 0) return;
    final proj = BoardProjection(side: _boardSide, tilt: _tilt);
    _projection = proj;

    // Eğik tahtanın gerçek sınır kutusunu çizim alanında ortala (dikeyde biraz
    // yukarı — ayakta duran taşlara ve yakın kenar gölgesine pay).
    final corners = [
      proj.project(const Offset(0, 0)),
      proj.project(Offset(_boardSide, 0)),
      proj.project(Offset(_boardSide, _boardSide)),
      proj.project(Offset(0, _boardSide)),
    ];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final c in corners) {
      minX = math.min(minX, c.dx);
      maxX = math.max(maxX, c.dx);
      minY = math.min(minY, c.dy);
      maxY = math.max(maxY, c.dy);
    }
    _origin = Offset(
      (size.x - (maxX - minX)) / 2 - minX,
      (size.y - (maxY - minY)) / 2 - minY - size.y * 0.01,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _targetTilt;
    if ((_tilt - target).abs() > 1e-4) {
      // yumuşak, ~0.35 sn oturan yaklaşım
      _tilt += (target - _tilt) * math.min(1.0, dt * 8.0);
      if ((_tilt - target).abs() <= 1e-4) _tilt = target;
      _rebuildProjection();
    }
  }

  /// Düz tahta pikseli → viewport pikseli.
  Offset _p(Offset flat) => _origin + _projection!.project(flat);

  @override
  void onTapDown(TapDownEvent event) {
    final proj = _projection;
    final m = _metrics;
    if (proj == null || m == null) return;
    final flat = proj.unproject(event.localPosition.toOffset() - _origin);
    controller.tapBoard(flat, m);
  }

  @override
  void render(Canvas canvas) {
    final m = _metrics;
    final proj = _projection;
    if (m == null || proj == null) return;

    final state = controller.state;
    final side = m.side;
    final cell = m.cell;

    // --- Zemin düzlemi: eğim izdüşümü altında çiz ---
    canvas.save();
    canvas.translate(_origin.dx, _origin.dy);
    canvas.transform(proj.canvasTransform());

    final img = _groundImage;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(0, 0, side, side),
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, side, side),
        Paint()..color = const Color(0xFF4E4231),
      );
    }

    // Derinlik gölgesi — uzak kenar koyu, yakın kenar hafif vinyet.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..shader = Gradient.linear(
          Offset(side / 2, 0),
          Offset(side / 2, side),
          _tilt >= 0
              ? const [Color(0x55000000), Color(0x08000000)]
              : const [Color(0x08000000), Color(0x55000000)],
        ),
    );

    // Yasal hamle vurguları.
    if (controller.mode == InteractionMode.move && !state.isOver) {
      final fill = Paint()..color = const Color(0x4048C774);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x9948C774);
      for (final sq in controller.legalStepTargets) {
        final g = m.cellCenter(sq);
        canvas.drawCircle(g, cell * 0.17, fill);
        canvas.drawCircle(g, cell * 0.17, ring);
      }
    }

    // Aktif askerin zemin nişanı (düzlemde — eğimle elips olur).
    if (!state.isOver) {
      final ac = m.cellCenter(state.pawnOf(state.turn));
      final rr = cell * 0.40;
      final reticle = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.035
        ..color = const Color(0xCCEDE7D6);
      canvas.drawCircle(ac, rr, reticle);
      for (final d in const [
        Offset(0, -1),
        Offset(0, 1),
        Offset(-1, 0),
        Offset(1, 0),
      ]) {
        canvas.drawLine(
          ac + Offset(d.dx * rr * 0.78, d.dy * rr * 0.78),
          ac + Offset(d.dx * rr * 1.18, d.dy * rr * 1.18),
          reticle,
        );
      }
    }

    // Yerleştirilmiş engeller + önizleme (zemin düzleminde).
    for (final b in state.barriers) {
      _drawBarrierFlat(canvas, m, b, preview: false, ok: true);
    }
    final preview = controller.preview;
    if (preview != null) {
      _drawBarrierFlat(canvas, m, preview,
          preview: true, ok: controller.canConfirmPreview);
    }

    canvas.restore();

    // --- Askerler: billboard (ekran uzayı) ---
    // Uzaktaki önce (derinlik sıralaması eğime göre).
    final p1Far = _tilt >= 0;
    void drawP1() => _drawSoldier(canvas, m, proj, state.pawnP1, _Faction.p1);
    void drawP2() => _drawSoldier(canvas, m, proj, state.pawnP2, _Faction.p2);
    if (p1Far) {
      drawP1();
      drawP2();
    } else {
      drawP2();
      drawP1();
    }
  }

  // ---------------------------------------------------------------------------
  // Zemin dokusu (bir kez üretilir)
  // ---------------------------------------------------------------------------

  void _bakeGround() {
    final m = _metrics;
    if (m == null || _boardSide <= 0) return;
    _groundImage?.dispose();

    const scale = 2.0;
    final n = m.boardSize;
    final side = _boardSide;
    final cell = m.cell;
    final px = (side * scale).ceil();

    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    c.scale(scale);
    final rnd = math.Random(20260906);

    // 1) Islak toprak taban degradesi.
    c.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, side),
          const [Color(0xFF645644), Color(0xFF4A3E2E)],
        ),
    );

    // 2a) Geniş açık kuru/kabarık alanlar (büyük tonal dalga).
    for (var i = 0; i < 12; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        cell * (0.7 + rnd.nextDouble() * 1.4),
        Paint()
          ..color = Color.fromRGBO(146, 128, 96, 0.05 + rnd.nextDouble() * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
    // 2b) Geniş koyu çamur birikintileri.
    for (var i = 0; i < 40; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        cell * (0.25 + rnd.nextDouble() * 0.9),
        Paint()
          ..color = Color.fromRGBO(26, 20, 13, 0.07 + rnd.nextDouble() * 0.11)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    // Açık kuru toz smear'ları.
    for (var i = 0; i < 18; i++) {
      c
        ..save()
        ..translate(rnd.nextDouble() * side, rnd.nextDouble() * side)
        ..rotate((rnd.nextDouble() - 0.5) * math.pi)
        ..drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: cell * (0.6 + rnd.nextDouble() * 1.6),
            height: cell * (0.10 + rnd.nextDouble() * 0.22),
          ),
          Paint()
            ..color =
                Color.fromRGBO(154, 136, 102, 0.04 + rnd.nextDouble() * 0.05)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        )
        ..restore();
    }

    // 3) Grain — ufak taş / is benekleri.
    for (var i = 0; i < 2400; i++) {
      final dark = rnd.nextInt(3) != 0;
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        0.6 + rnd.nextDouble() * 1.7,
        Paint()
          ..color = dark
              ? Color.fromRGBO(18, 14, 9, 0.06 + rnd.nextDouble() * 0.20)
              : Color.fromRGBO(158, 142, 110, 0.05 + rnd.nextDouble() * 0.12),
      );
    }

    // 4) Kraterler (sabit yerleşim) — düzensiz koyu ezikler, geometrik halka yok.
    final cr = math.Random(31);
    for (var i = 0; i < 5; i++) {
      final p = Offset(
        side * (0.14 + 0.72 * cr.nextDouble()),
        side * (0.14 + 0.72 * cr.nextDouble()),
      );
      final rad = cell * (0.5 + cr.nextDouble() * 0.6);
      for (var k = 0; k < 3; k++) {
        final off = Offset(
          (cr.nextDouble() - 0.5) * rad * 0.7,
          (cr.nextDouble() - 0.5) * rad * 0.7,
        );
        c.drawCircle(
          p + off,
          rad * (0.55 + cr.nextDouble() * 0.5),
          Paint()
            ..color = Color.fromRGBO(15, 10, 6, 0.14 + cr.nextDouble() * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      // Saçılmış toprak (kraterin bir yanında hafif açık).
      c.drawCircle(
        p + Offset(rad * 0.6, -rad * 0.5),
        rad * 0.7,
        Paint()
          ..color = const Color(0x14A08A64)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // 5) Hedef sektörleri (üst = mavi P1 hedefi, alt = kırmızı P2 hedefi).
    _bakeSector(
        c, Rect.fromLTWH(0, 0, side, cell), const Color(0xFF3E6E9E), atTop: true);
    _bakeSector(c, Rect.fromLTWH(0, side - cell, side, cell),
        const Color(0xFFA2433B),
        atTop: false);

    // 6) Yıpranmış ızgara.
    for (var i = 0; i <= n; i++) {
      _wornGridLine(c, Offset(i * cell, 0), Offset(i * cell, side), rnd);
      _wornGridLine(c, Offset(0, i * cell), Offset(side, i * cell), rnd);
    }

    // 7) İç sınır — parapet (siper duvarı) gölgesi + kenar dudağı ışığı.
    c
      ..drawRect(
        Rect.fromLTWH(0, 0, side, side).deflate(cell * 0.04),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.14
          ..color = const Color(0x4D000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRect(
        Rect.fromLTWH(0, 0, side, side),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x59140D08),
      );
    // Üst ve alt siper kenarında hafif yakalanan ışık.
    for (final atTop in const [true, false]) {
      final y = atTop ? 0.0 : side;
      c.drawRect(
        Rect.fromLTWH(0, y - (atTop ? 0 : cell * 0.5), side, cell * 0.5),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, atTop ? 0 : side),
            Offset(0, atTop ? cell * 0.5 : side - cell * 0.5),
            const [Color(0x1FA79068), Color(0x00A79068)],
          ),
      );
    }

    final picture = recorder.endRecording();
    _groundImage = picture.toImageSync(px, px);
    picture.dispose();
  }

  void _bakeSector(Canvas c, Rect r, Color color, {required bool atTop}) {
    c.drawRect(r, Paint()..color = color.withValues(alpha: 0.17));

    // Çapraz tehlike şeritleri.
    c
      ..save()
      ..clipRect(r);
    final stripe = Paint()
      ..color = color.withValues(alpha: 0.09)
      ..strokeWidth = r.height * 0.34;
    for (var x = -r.height; x < r.width + r.height; x += r.height * 0.9) {
      c.drawLine(
        Offset(r.left + x, r.top),
        Offset(r.left + x + r.height, r.bottom),
        stripe,
      );
    }
    c.restore();

    // Hedef kenarında şablon (stencil) kesikli çizgi.
    final y = atTop ? r.bottom - 2.5 : r.top + 2.5;
    final dash = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    const segs = 26;
    for (var i = 0; i < segs; i += 2) {
      final x0 = r.left + r.width * i / segs;
      c.drawLine(Offset(x0, y), Offset(x0 + r.width / segs * 0.7, y), dash);
    }
  }

  void _wornGridLine(Canvas c, Offset a, Offset b, math.Random rnd) {
    const segs = 12;
    final dark = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = const Color(0xA32A2118);
    final lip = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1
      ..color = const Color(0x30837155);
    for (var s = 0; s < segs; s++) {
      if (rnd.nextDouble() < 0.10) continue;
      Offset j() => Offset(
            (rnd.nextDouble() - 0.5) * 2.2,
            (rnd.nextDouble() - 0.5) * 2.2,
          );
      final p0 = Offset.lerp(a, b, s / segs)! + j();
      final p1 = Offset.lerp(a, b, (s + 1) / segs)! + j();
      c
        ..drawLine(p0, p1, dark)
        ..drawLine(p0.translate(-0.7, -0.7), p1.translate(-0.7, -0.7), lip);
    }
  }

  // ---------------------------------------------------------------------------
  // Dinamik katmanlar
  // ---------------------------------------------------------------------------

  void _drawBarrierFlat(
    Canvas canvas,
    BoardMetrics m,
    Barrier b, {
    required bool preview,
    required bool ok,
  }) {
    final (a, z) = m.barrierLine(b);
    final w = m.cell * 0.16;

    final base = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w
      ..color = const Color(0xCC1A140D);
    final Color topColor;
    if (preview) {
      topColor = ok ? const Color(0xEE5ED17A) : const Color(0xEEE5615C);
    } else {
      topColor = b.isWire ? const Color(0xFF2A2620) : const Color(0xFFD79A2B);
    }
    final top = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.58
      ..color = topColor;

    canvas
      ..drawLine(a, z, base)
      ..drawLine(a, z, top);
  }

  /// "Miğferli mevzi" askeri: kazılı toprak taban + siper (brim) + miğfer
  /// kubbesi. Billboard — ekran uzayında dik durur, derinliğe göre ölçeklenir.
  void _drawSoldier(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Square sq,
    _Faction fac,
  ) {
    final g = m.cellCenter(sq);
    final gs = _p(g);
    final sc = proj.scaleAt(g);
    final vRatio = (proj.verticalScaleAt(g) / sc).clamp(0.25, 1.0);
    final r = m.cell * 0.36 * sc;

    final groundY = gs.dy;
    final brimY = groundY - r * 0.52;
    final rh = r * 0.92;
    final domeC = Offset(gs.dx, brimY - rh * 0.58);

    // 1) Zemin gölgesi.
    canvas.drawOval(
      Rect.fromCenter(
        center: gs,
        width: r * 2.7,
        height: r * 2.7 * vRatio * 0.5,
      ),
      Paint()
        ..color = const Color(0x78000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2) Kazılı mevzi tabanı (toprak halkası).
    final moundW = r * 2.35;
    final moundH = r * 0.78 * vRatio + r * 0.3;
    final moundRect = Rect.fromCenter(
      center: Offset(gs.dx, groundY - r * 0.1),
      width: moundW,
      height: moundH,
    );
    canvas
      ..drawOval(
        moundRect.inflate(r * 0.08),
        Paint()..color = const Color(0xFF241F17),
      )
      ..drawOval(moundRect, Paint()..color = const Color(0xFF4A3F2E))
      ..drawArc(
        moundRect,
        math.pi * 1.12,
        math.pi * 0.76,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08
          ..color = const Color(0x3AC9B48A),
      );

    // 3) Miğfer kubbesi — tam daire (alt kısmı brim'in arkasında kalır).
    final domeRect = Rect.fromCircle(center: domeC, radius: rh);
    canvas
      ..drawCircle(
        domeC,
        rh,
        Paint()
          ..shader = Gradient.radial(
            domeC + Offset(-rh * 0.36, -rh * 0.42),
            rh * 1.9,
            [fac.lit, fac.mid, fac.dark],
            const [0.0, 0.46, 1.0],
          ),
      )
      // Sağ-alt gövde gölgesi.
      ..drawArc(
        domeRect.deflate(rh * 0.04),
        -math.pi * 0.18,
        math.pi * 0.62,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rh * 0.5
          ..color = const Color(0x2E140D08),
      )
      // Üst-sol kenar ışığı.
      ..drawArc(
        domeRect.deflate(rh * 0.06),
        math.pi * 1.16,
        math.pi * 0.42,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rh * 0.13
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x9EF3ECDC),
      );

    // 4) Siper (brim) — miğferin oturduğu disk; kubbenin alt kısmını örter.
    final brimRect = Rect.fromCenter(
      center: Offset(gs.dx, brimY),
      width: rh * 2.5,
      height: rh * 0.62 * vRatio + rh * 0.28,
    );
    canvas
      ..drawOval(brimRect.shift(Offset(0, r * 0.04)),
          Paint()..color = const Color(0x552A1C12))
      ..drawOval(brimRect, Paint()..color = fac.brim)
      ..drawArc(
        brimRect,
        math.pi * 1.1,
        math.pi * 0.75,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = const Color(0x66F3ECDC),
      );

    // 5) İnce dış hat (yalnız görünen üst kubbe) — okunurluk.
    canvas.drawArc(
      domeRect,
      math.pi * 0.96,
      math.pi * 1.08,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x3A120C07),
    );
  }
}

/// Bir tarafın miğfer renk tonları (aynı form, farklı renk — [Faction] simetrik).
class _Faction {
  const _Faction(this.mid, this.lit, this.dark, this.brim);

  final Color mid;
  final Color lit;
  final Color dark;
  final Color brim;

  static const p1 = _Faction(
    Color(0xFF3E6E9E),
    Color(0xFF6796C2),
    Color(0xFF294C6E),
    Color(0xFF32587E),
  );
  static const p2 = _Faction(
    Color(0xFFA2433B),
    Color(0xFFC96A5E),
    Color(0xFF6F2C26),
    Color(0xFF83352D),
  );
}
