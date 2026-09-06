import 'dart:ui';

import 'package:game_core/game_core.dart';

/// Tahta koordinatları (kare / kenar) ile piksel koordinatları arasında çeviri.
///
/// `game_core` satır 0'ı **altta** kabul eder; ekran y'si aşağı doğru artar —
/// çeviriyi burada yapıyoruz. Pikseller tahtanın sol-üst köşesine göredir (0..[side]).
class BoardMetrics {
  BoardMetrics({required this.boardSize, required this.side})
      : cell = side / boardSize;

  final int boardSize;
  final double side;
  final double cell;

  double _screenTop(int row) => (boardSize - 1 - row) * cell;

  Rect cellRect(Square s) =>
      Rect.fromLTWH(s.col * cell, _screenTop(s.row), cell, cell);

  Offset cellCenter(Square s) => cellRect(s).center;

  /// Bir piksel noktasının düştüğü kare; tahta dışındaysa `null`.
  Square? squareAt(Offset p) {
    if (p.dx < 0 || p.dy < 0 || p.dx >= side || p.dy >= side) return null;
    final col = (p.dx / cell).floor();
    final row = boardSize - 1 - (p.dy / cell).floor();
    return Square(col, row);
  }

  /// Bir engelin kapattığı kenar(lar)ını çizmek için çizgi (iki uç nokta).
  (Offset, Offset) barrierLine(Barrier b) {
    final c = b.anchor.col;
    final r = b.anchor.row;
    switch (b.orientation) {
      case BarrierOrientation.horizontal:
        final y = _screenTop(r);
        final span = b.isWire ? 2 : 1;
        return (Offset(c * cell, y), Offset((c + span) * cell, y));
      case BarrierOrientation.vertical:
        final x = (c + 1) * cell;
        final yLow = _screenTop(r) + cell;
        final yHigh = b.isWire ? _screenTop(r) - cell : _screenTop(r);
        return (Offset(x, yLow), Offset(x, yHigh));
    }
  }

  /// [p] noktasına en yakın engel adayı. Geçerli aralığa kırpılır; yasallığı
  /// [Rules.canPlaceBarrier] ile çağıran kontrol eder.
  Barrier nearestBarrierSlot(Offset p, BarrierType type) {
    // En yakın iç dikey/yatay ızgara çizgisi (indeks 1..boardSize-1).
    final vLine = (p.dx / cell).round().clamp(1, boardSize - 1);
    final hLine = (p.dy / cell).round().clamp(1, boardSize - 1);
    final horizontal = (p.dy - hLine * cell).abs() < (p.dx - vLine * cell).abs();

    if (horizontal) {
      final row = boardSize - 1 - hLine; // kuzey kenarı olan kare satırı
      final maxCol = type == BarrierType.wire ? boardSize - 2 : boardSize - 1;
      final col = (p.dx / cell).floor().clamp(0, maxCol);
      return Barrier(
        type: type,
        orientation: BarrierOrientation.horizontal,
        anchor: Square(col, row.clamp(0, boardSize - 2)),
      );
    } else {
      final col = vLine - 1; // doğu kenarı olan kare sütunu
      final maxRow = type == BarrierType.wire ? boardSize - 2 : boardSize - 1;
      final row = (boardSize - 1 - (p.dy / cell).floor()).clamp(0, maxRow);
      return Barrier(
        type: type,
        orientation: BarrierOrientation.vertical,
        anchor: Square(col.clamp(0, boardSize - 2), row),
      );
    }
  }

}
