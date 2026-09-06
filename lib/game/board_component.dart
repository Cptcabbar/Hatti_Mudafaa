import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:game_core/game_core.dart';

import 'board_metrics.dart';
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

  BoardMetrics? get metrics => _metrics;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final boardSide = size.x < size.y ? size.x : size.y;
    _metrics = BoardMetrics(
      boardSize: controller.state.config.boardSize,
      side: boardSide,
    );
    this.size = Vector2.all(boardSide);
    position = Vector2((size.x - boardSide) / 2, (size.y - boardSide) / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final m = _metrics;
    if (m == null) return;
    controller.tapBoard(event.localPosition.toOffset(), m);
  }

  @override
  void render(Canvas canvas) {
    final m = _metrics;
    if (m == null) return;
    final state = controller.state;
    final side = m.side;
    final cell = m.cell;

    // Zemin.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..color = const Color(0xFF6B6141),
    );

    // Hedef satır tintleri (üst = P1, alt = P2).
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, cell),
      Paint()..color = const Color(0x333E6E9E),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, side - cell, side, cell),
      Paint()..color = const Color(0x33A2433B),
    );

    // Izgara.
    final grid = Paint()
      ..color = const Color(0xFF574F35)
      ..strokeWidth = 1.5;
    for (var i = 0; i <= m.boardSize; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, side), grid);
      canvas.drawLine(Offset(0, i * cell), Offset(side, i * cell), grid);
    }

    // Yasal hamle vurguları (move modu).
    if (controller.mode == InteractionMode.move && !state.isOver) {
      final hl = Paint()..color = const Color(0x5548C774);
      for (final sq in controller.legalStepTargets) {
        canvas.drawCircle(m.cellCenter(sq), cell * 0.16, hl);
      }
    }

    // Yerleştirilmiş engeller.
    final barrier = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell * 0.14;
    for (final b in state.barriers) {
      barrier.color =
          b.isWire ? const Color(0xFF2E2A20) : const Color(0xFFE0A72E);
      final (a, z) = m.barrierLine(b);
      canvas.drawLine(a, z, barrier);
    }

    // Engel önizlemesi.
    final preview = controller.preview;
    if (preview != null) {
      final ok = controller.canConfirmPreview;
      final pp = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = cell * 0.14
        ..color = ok ? const Color(0xAA48C774) : const Color(0xAAE5484D);
      final (a, z) = m.barrierLine(preview);
      canvas.drawLine(a, z, pp);
    }

    // Piyonlar.
    _drawPawn(canvas, m, state.pawnP1, const Color(0xFF3E6E9E));
    _drawPawn(canvas, m, state.pawnP2, const Color(0xFFA2433B));

    // Sıradaki askerin halkası.
    if (!state.isOver) {
      canvas.drawCircle(
        m.cellCenter(state.pawnOf(state.turn)),
        cell * 0.38,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFEDE7D6),
      );
    }
  }

  void _drawPawn(Canvas canvas, BoardMetrics m, Square sq, Color color) {
    final center = m.cellCenter(sq);
    canvas.drawCircle(center, m.cell * 0.30, Paint()..color = color);
    canvas.drawCircle(
      center,
      m.cell * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF14110D),
    );
  }
}
