import 'board_state.dart';
import 'config.dart';
import 'move.dart';

/// Bir oyunun tam kaydı: yapılandırma + sıralı hamle listesi.
///
/// `docs/rules.md` §7: "Bir oyun = `GameConfig` + başlangıç konfigürasyonu +
/// sıralı hamle listesi." Tekrar oynatma ve online senkron için.
class GameRecord {
  GameRecord({required this.config, List<Move>? moves})
      : moves = moves ?? <Move>[];

  final GameConfig config;
  final List<Move> moves;

  /// Boşlukla ayrılmış hamle notasyonu: `"d2 Wc3h e5 ..."`.
  String movesText() => moves.map((m) => m.toNotation()).join(' ');

  /// [movesText] biçiminden okur.
  factory GameRecord.parse({
    required GameConfig config,
    required String movesText,
  }) {
    final tokens = movesText
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(Move.parse)
        .toList();
    return GameRecord(config: config, moves: tokens);
  }

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'moves': moves.map((m) => m.toNotation()).toList(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
        moves: (json['moves'] as List<dynamic>)
            .map((s) => Move.parse(s as String))
            .toList(),
      );

  /// Başlangıç durumu (henüz hamle uygulanmamış).
  BoardState initialState() => BoardState.initial(config);
}
