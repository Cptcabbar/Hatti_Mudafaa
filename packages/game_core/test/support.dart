import 'package:game_core/game_core.dart';

/// Test için özel bir [BoardState] kurar (yerleştirme doğrulaması yapılmaz).
BoardState buildState({
  GameConfig config = GameConfig.v1,
  String p1 = 'd1',
  String p2 = 'd7',
  List<String> barriers = const [],
  Player turn = Player.p1,
  int? armoryP1,
  int? armoryP2,
  int ply = 0,
}) {
  return BoardState(
    config: config,
    pawnP1: Square.parse(p1),
    pawnP2: Square.parse(p2),
    barriers: barriers.map(Barrier.parse).toList(),
    turn: turn,
    armoryP1: armoryP1 ?? config.armoryPoints,
    armoryP2: armoryP2 ?? config.armoryPoints,
    ply: ply,
  );
}

/// Sıradaki askerin gidebileceği kareler, notasyon kümesi olarak.
Set<String> stepTargets(BoardState state) =>
    Rules.pawnMoves(state).map((m) => m.to.toString()).toSet();

/// Yasal engel hamleleri, notasyon kümesi olarak.
Set<String> barrierTargets(BoardState state) =>
    Rules.barrierMoves(state).map((m) => m.barrier.toNotation()).toSet();
