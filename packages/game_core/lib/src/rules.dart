import 'barrier.dart';
import 'board_state.dart';
import 'coord.dart';
import 'move.dart';
import 'pathfinding.dart';

/// Bir kural ihlali.
class IllegalMoveException implements Exception {
  const IllegalMoveException(this.reason);
  final String reason;
  @override
  String toString() => 'IllegalMoveException: $reason';
}

/// Hattı Müdafaa kural motoru — tek doğruluk kaynağı `docs/rules.md`.
///
/// Yerel oyun, `game_ai` ve online doğrulama hep buradan geçer. Girdi durumları
/// asla değiştirilmez; her uygulama yeni bir [BoardState] üretir.
abstract final class Rules {
  /// [state] konumunda sıradaki oyuncunun yapabileceği tüm yasal hamleler.
  static List<Move> legalMoves(BoardState state) {
    if (state.isOver) return const [];
    return [...pawnMoves(state), ...barrierMoves(state)];
  }

  /// §4 — sıradaki askerin gidebileceği kareler (hareket + atlama).
  static List<StepMove> pawnMoves(BoardState state) {
    final size = state.config.boardSize;
    final me = state.turn;
    final from = state.pawnOf(me);
    final opp = state.pawnOf(me.other);
    final moves = <StepMove>[];

    bool inBounds(Square s) =>
        s.col >= 0 && s.col < size && s.row >= 0 && s.row < size;

    for (final dir in Direction.values) {
      final adj = from.step(dir);
      if (!inBounds(adj)) continue;
      if (state.isEdgeBlocked(from, adj)) continue;
      // Engel karesine (§2.1) girilemez — rakip de orada duramaz, tümden atla.
      if (state.isObstacle(adj)) continue;

      if (adj != opp) {
        moves.add(StepMove(adj));
        continue;
      }

      // Rakip komşu karede — atlama (§4.2).
      final beyond = adj.step(dir);
      final straightOpen = inBounds(beyond) &&
          !state.isEdgeBlocked(adj, beyond) &&
          !state.isObstacle(beyond);
      if (straightOpen) {
        moves.add(StepMove(beyond));
        continue;
      }
      // Düz atlama kapalı → koşullu çapraz.
      for (final perp in dir.perpendiculars) {
        final diag = adj.step(perp);
        if (!inBounds(diag)) continue;
        if (state.isEdgeBlocked(adj, diag)) continue;
        if (state.isObstacle(diag)) continue;
        moves.add(StepMove(diag));
      }
    }
    return moves;
  }

  /// §5 — sıradaki oyuncunun koyabileceği tüm yasal engeller.
  static List<PlaceBarrierMove> barrierMoves(BoardState state) {
    final config = state.config;
    final armory = state.armoryOf(state.turn);
    final size = config.boardSize;
    final moves = <PlaceBarrierMove>[];

    final types = <BarrierType>[
      if (armory >= config.mineCost) BarrierType.mine,
      if (armory >= config.wireCost) BarrierType.wire,
    ];

    for (final type in types) {
      for (final orientation in BarrierOrientation.values) {
        final maxCol = _maxAnchorCol(type, orientation, size);
        final maxRow = _maxAnchorRow(type, orientation, size);
        for (var c = 0; c <= maxCol; c++) {
          for (var r = 0; r <= maxRow; r++) {
            final barrier = Barrier(
              type: type,
              orientation: orientation,
              anchor: Square(c, r),
            );
            if (canPlaceBarrier(state, barrier)) {
              moves.add(PlaceBarrierMove(barrier));
            }
          }
        }
      }
    }
    return moves;
  }

  /// Bir engel yerleştirmenin §5.3 dört koşulunu sağlayıp sağlamadığı.
  static bool canPlaceBarrier(BoardState state, Barrier barrier) {
    final config = state.config;

    // 1. Sınır — kapattığı tüm kenarlar tahtada.
    for (final edge in barrier.blockedEdges()) {
      if (!config.isSquareInBounds(edge.a) || !config.isSquareInBounds(edge.b)) {
        return false;
      }
    }

    // 2. Çakışma yasak.
    if (state.overlapsExistingBarrier(barrier)) return false;

    // 3. Tel + tel aynı pivotta dik kesişemez (mayın bu kısıtın dışında).
    if (barrier.isWire) {
      for (final existing in state.barriers) {
        if (existing.isWire &&
            existing.anchor == barrier.anchor &&
            existing.orientation != barrier.orientation) {
          return false;
        }
      }
    }

    // 4. Yol kapatma yasağı — her iki asker de hedefine ulaşabilmeli.
    final probe = state.copyWith(barriers: [...state.barriers, barrier]);
    return Pathfinding.hasPathToRow(
          probe,
          probe.pawnP1,
          probe.goalRowOf(Player.p1),
        ) &&
        Pathfinding.hasPathToRow(
          probe,
          probe.pawnP2,
          probe.goalRowOf(Player.p2),
        );
  }

  /// [move] bu konumda yasal mı?
  static bool isLegal(BoardState state, Move move) =>
      legalMoves(state).contains(move);

  /// [move]'u uygular ve yeni durumu döndürür. Yasadışıysa
  /// [IllegalMoveException] atar. [state] değişmez.
  ///
  /// [validate] `false` verilirse yasallık kontrolü atlanır — yalnızca
  /// [legalMoves]'tan gelen bir hamle için güvenlidir (AI sıcak yolu).
  static BoardState applyMove(
    BoardState state,
    Move move, {
    bool validate = true,
  }) {
    if (state.isOver) {
      throw const IllegalMoveException('Oyun zaten bitti');
    }
    if (validate && !isLegal(state, move)) {
      throw IllegalMoveException('Yasadışı hamle: ${move.toNotation()}');
    }

    final me = state.turn;
    switch (move) {
      case StepMove(:final to):
        // state.isOver false → state.winner null; kazanan yalnızca burada set edilir.
        final reachedGoal = to.row == state.goalRowOf(me);
        return state.copyWith(
          pawnP1: me == Player.p1 ? to : state.pawnP1,
          pawnP2: me == Player.p2 ? to : state.pawnP2,
          turn: me.other,
          ply: state.ply + 1,
          winner: reachedGoal ? me : null,
        );
      case PlaceBarrierMove(:final barrier):
        final cost = barrier.cost(state.config);
        return state.copyWith(
          barriers: [...state.barriers, barrier],
          armoryP1: me == Player.p1 ? state.armoryP1 - cost : state.armoryP1,
          armoryP2: me == Player.p2 ? state.armoryP2 - cost : state.armoryP2,
          turn: me.other,
          ply: state.ply + 1,
        );
    }
  }

  static int _maxAnchorCol(BarrierType type, BarrierOrientation o, int size) {
    // Yatay mayın tek dikey kenarı kapatır → sütun size-1'e kadar.
    if (type == BarrierType.mine && o == BarrierOrientation.horizontal) {
      return size - 1;
    }
    return size - 2;
  }

  static int _maxAnchorRow(BarrierType type, BarrierOrientation o, int size) {
    // Dikey mayın tek yatay kenarı kapatır → satır size-1'e kadar.
    if (type == BarrierType.mine && o == BarrierOrientation.vertical) {
      return size - 1;
    }
    return size - 2;
  }
}
