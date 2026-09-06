import 'barrier.dart';
import 'config.dart';
import 'coord.dart';

/// Oyuncu kimliği.
enum Player {
  /// Mavi. `d1`'den başlar, en üst satıra ulaşmaya çalışır.
  p1,

  /// Kırmızı. `d7`'den başlar, en alt satıra ulaşmaya çalışır.
  p2;

  Player get other => this == Player.p1 ? Player.p2 : Player.p1;
}

/// Oyunun tam durumu — **değişmez (immutable)**. `docs/rules.md` §7.
///
/// Kural motoru ([applyMove], Faz 1) bir [BoardState] alıp yenisini üretir;
/// mevcut örnek asla değiştirilmez.
class BoardState {
  BoardState({
    required this.config,
    required this.pawnP1,
    required this.pawnP2,
    required List<Barrier> barriers,
    required this.turn,
    required this.armoryP1,
    required this.armoryP2,
    this.ply = 0,
    this.winner,
  })  : barriers = List.unmodifiable(barriers),
        _blockedEdges = _indexBlockedEdges(barriers);

  final GameConfig config;
  final Square pawnP1;
  final Square pawnP2;
  final List<Barrier> barriers;
  final Player turn;
  final int armoryP1;
  final int armoryP2;

  /// Kaçıncı hamle (0'dan başlar).
  final int ply;

  /// Oyunu kazanan oyuncu; oyun sürüyorsa `null`.
  final Player? winner;

  final Set<Edge> _blockedEdges;

  /// Standart başlangıç durumu.
  factory BoardState.initial([GameConfig config = GameConfig.v1]) {
    return BoardState(
      config: config,
      pawnP1: config.startP1,
      pawnP2: config.startP2,
      barriers: const [],
      turn: Player.p1,
      armoryP1: config.armoryPoints,
      armoryP2: config.armoryPoints,
    );
  }

  static Set<Edge> _indexBlockedEdges(List<Barrier> barriers) {
    final set = <Edge>{};
    for (final b in barriers) {
      set.addAll(b.blockedEdges());
    }
    return set;
  }

  bool get isOver => winner != null;

  Square pawnOf(Player p) => p == Player.p1 ? pawnP1 : pawnP2;

  int armoryOf(Player p) => p == Player.p1 ? armoryP1 : armoryP2;

  /// Oyuncunun ulaşması gereken hedef satır (0 tabanlı).
  int goalRowOf(Player p) => p == Player.p1 ? config.boardSize - 1 : 0;

  /// İki komşu kare arasındaki geçiş bir engelle kapalı mı?
  bool isEdgeBlocked(Square a, Square b) =>
      _blockedEdges.contains(Edge.between(a, b));

  BoardState copyWith({
    Square? pawnP1,
    Square? pawnP2,
    List<Barrier>? barriers,
    Player? turn,
    int? armoryP1,
    int? armoryP2,
    int? ply,
    Player? winner,
  }) {
    return BoardState(
      config: config,
      pawnP1: pawnP1 ?? this.pawnP1,
      pawnP2: pawnP2 ?? this.pawnP2,
      barriers: barriers ?? this.barriers,
      turn: turn ?? this.turn,
      armoryP1: armoryP1 ?? this.armoryP1,
      armoryP2: armoryP2 ?? this.armoryP2,
      ply: ply ?? this.ply,
      winner: winner ?? this.winner,
    );
  }

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'pawnP1': pawnP1.toString(),
        'pawnP2': pawnP2.toString(),
        'barriers': barriers.map((b) => b.toNotation()).toList(),
        'turn': turn.name,
        'armoryP1': armoryP1,
        'armoryP2': armoryP2,
        'ply': ply,
        'winner': winner?.name,
      };

  factory BoardState.fromJson(Map<String, dynamic> json) {
    final winnerName = json['winner'] as String?;
    return BoardState(
      config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
      pawnP1: Square.parse(json['pawnP1'] as String),
      pawnP2: Square.parse(json['pawnP2'] as String),
      barriers: (json['barriers'] as List<dynamic>)
          .map((s) => Barrier.parse(s as String))
          .toList(),
      turn: Player.values.byName(json['turn'] as String),
      armoryP1: json['armoryP1'] as int,
      armoryP2: json['armoryP2'] as int,
      ply: json['ply'] as int? ?? 0,
      winner: winnerName == null ? null : Player.values.byName(winnerName),
    );
  }

  @override
  String toString() =>
      'BoardState(ply:$ply turn:${turn.name} p1:$pawnP1 p2:$pawnP2 '
      'armory:$armoryP1/$armoryP2 barriers:${barriers.length}'
      '${winner != null ? ' winner:${winner!.name}' : ''})';
}
