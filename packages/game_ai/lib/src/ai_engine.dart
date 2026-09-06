import 'package:game_core/game_core.dart';

/// Yapay zeka zorluk seviyesi. `docs` / ROADMAP Faz 2.
enum AiDifficulty {
  /// Sığ arama + ara sıra hatalı hamle + engelleri nadiren kullanır.
  easy,

  /// Makul derinlik + iyi engel kullanımı.
  medium,

  /// Tam derinlik + optimuma yakın.
  hard,
}

/// Bir konum için hamle seçen yapay zeka.
///
/// **Faz 2'de uygulanacak** (negamax + alpha-beta + BFS değerlendirme,
/// `game_ai` bir isolate içinde çalışır).
abstract interface class AiEngine {
  /// [state] konumunda sıradaki oyuncu için bir hamle seçer.
  ///
  /// [budget] kadar süre içinde dönmelidir (iterative deepening).
  Future<Move> chooseMove(BoardState state, {required Duration budget});
}
