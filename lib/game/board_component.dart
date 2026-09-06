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
    _rebuildProjection();
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

    // --- Zemin ---
    final ground = Path()
      ..addPolygon([
        _p(const Offset(0, 0)),
        _p(Offset(side, 0)),
        _p(Offset(side, side)),
        _p(Offset(0, side)),
      ], true);

    canvas.drawPath(ground, Paint()..color = const Color(0xFF6B6141));
    // Uzak kenara doğru koyulaşan derinlik gölgesi.
    canvas.drawPath(
      ground,
      Paint()
        ..shader = Gradient.linear(
          _p(Offset(side / 2, 0)),
          _p(Offset(side / 2, side)),
          _tilt >= 0
              ? const [Color(0x33000000), Color(0x00000000)]
              : const [Color(0x00000000), Color(0x33000000)],
        ),
    );

    // Hedef satır tintleri (üst = P1 mavi, alt = P2 kırmızı).
    canvas.drawPath(
      Path()
        ..addPolygon([
          _p(const Offset(0, 0)),
          _p(Offset(side, 0)),
          _p(Offset(side, cell)),
          _p(Offset(0, cell)),
        ], true),
      Paint()..color = const Color(0x333E6E9E),
    );
    canvas.drawPath(
      Path()
        ..addPolygon([
          _p(Offset(0, side - cell)),
          _p(Offset(side, side - cell)),
          _p(Offset(side, side)),
          _p(Offset(0, side)),
        ], true),
      Paint()..color = const Color(0x33A2433B),
    );

    // Izgara.
    final grid = Paint()
      ..color = const Color(0xFF574F35)
      ..strokeWidth = 1.5;
    for (var i = 0; i <= m.boardSize; i++) {
      canvas.drawLine(_p(Offset(i * cell, 0)), _p(Offset(i * cell, side)), grid);
      canvas.drawLine(_p(Offset(0, i * cell)), _p(Offset(side, i * cell)), grid);
    }

    // Yasal hamle vurguları (move modu).
    if (controller.mode == InteractionMode.move && !state.isOver) {
      final hl = Paint()..color = const Color(0x5548C774);
      for (final sq in controller.legalStepTargets) {
        final g = m.cellCenter(sq);
        canvas.drawCircle(_p(g), cell * 0.16 * proj.scaleAt(g), hl);
      }
    }

    // Yerleştirilmiş engeller.
    for (final b in state.barriers) {
      _drawBarrier(
        canvas,
        m,
        proj,
        b,
        b.isWire ? const Color(0xFF2E2A20) : const Color(0xFFE0A72E),
      );
    }

    // Engel önizlemesi.
    final preview = controller.preview;
    if (preview != null) {
      final ok = controller.canConfirmPreview;
      _drawBarrier(
        canvas,
        m,
        proj,
        preview,
        ok ? const Color(0xAA48C774) : const Color(0xAAE5484D),
      );
    }

    // Piyonlar (billboard + zemin gölgesi).
    _drawPawn(canvas, m, proj, state.pawnP1, const Color(0xFF3E6E9E),
        active: !state.isOver && state.turn == Player.p1);
    _drawPawn(canvas, m, proj, state.pawnP2, const Color(0xFFA2433B),
        active: !state.isOver && state.turn == Player.p2);
  }

  void _drawBarrier(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Barrier b,
    Color color,
  ) {
    final (a, z) = m.barrierLine(b);
    final mid = Offset.lerp(a, z, 0.5)!;
    final sc = proj.scaleAt(mid);
    canvas.drawLine(
      _p(a),
      _p(z),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = m.cell * 0.14 * sc
        ..color = color,
    );
  }

  void _drawPawn(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Square sq,
    Color color, {
    required bool active,
  }) {
    final g = m.cellCenter(sq);
    final gs = _p(g);
    final sc = proj.scaleAt(g);
    final vsc = proj.verticalScaleAt(g);
    final r = m.cell * 0.30 * sc;
    final lift = m.cell * 0.34 * sc;

    // Zemin gölgesi.
    canvas.drawOval(
      Rect.fromCenter(
        center: gs,
        width: r * 2.1,
        height: r * 2.1 * (vsc / sc).clamp(0.25, 1.0) * 0.7,
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final center = gs + Offset(0, -lift);

    if (active) {
      canvas.drawCircle(
        center,
        r * 1.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFEDE7D6),
      );
    }

    canvas.drawCircle(center, r, Paint()..color = color);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF14110D),
    );
  }
}
