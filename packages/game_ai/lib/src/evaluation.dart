import 'package:game_core/game_core.dart';

/// Bir konumun statik değeri — **sıradaki oyuncunun** gözünden (negamax).
///
/// Temel sezgi: bu bir yarış. En güçlü terim iki askerin hedefe olan **en kısa
/// yol farkı** (`docs/rules.md` §5.3/4 ile aynı BFS). Kalan cephanelik küçük
/// bir varlık, tempo küçük bir avantaj.
abstract final class Evaluation {
  /// Kazanma/kaybetme uç değeri (ply ile ölçeklenir → hızlı kazanç yeğlenir).
  static const int win = 100000;

  static const int _wDist = 10;
  static const int _wArmory = 2;
  static const int _tempo = 3;

  /// [state] konumunun, **[state.turn]** oyuncusu için değeri. Yüksek = iyi.
  static int forSideToMove(BoardState state) => _score(state, state.turn);

  /// [state] konumunun [me] oyuncusu için değeri.
  static int score(BoardState state, Player me) => _score(state, me);

  static int _score(BoardState s, Player me) {
    final other = me.other;
    if (s.winner == me) return win - s.ply;
    if (s.winner == other) return -win + s.ply;

    final myDist = Pathfinding.shortestDistanceToRow(
          s,
          s.pawnOf(me),
          s.goalRowOf(me),
        ) ??
        999;
    final opDist = Pathfinding.shortestDistanceToRow(
          s,
          s.pawnOf(other),
          s.goalRowOf(other),
        ) ??
        999;

    var v = (opDist - myDist) * _wDist;
    v += (s.armoryOf(me) - s.armoryOf(other)) * _wArmory;
    v += s.turn == me ? _tempo : -_tempo;
    return v;
  }
}
