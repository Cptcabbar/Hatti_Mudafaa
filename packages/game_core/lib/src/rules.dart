import 'board_state.dart';
import 'move.dart';

/// Sonucu belli olan bir kural ihlali.
class IllegalMoveException implements Exception {
  const IllegalMoveException(this.reason);
  final String reason;
  @override
  String toString() => 'IllegalMoveException: $reason';
}

/// Kapalı Yol kural motoru — tek doğruluk kaynağı `docs/rules.md`.
///
/// **Faz 1'de uygulanacak.** Yerel oyun, `game_ai` ve online doğrulama hep
/// buradan geçer.
abstract final class Rules {
  /// [state] konumunda sıradaki oyuncunun yapabileceği tüm yasal hamleler.
  static List<Move> legalMoves(BoardState state) {
    throw UnimplementedError('Faz 1: hamle üretimi (§4, §5)');
  }

  /// [move] bu konumda yasal mı?
  static bool isLegal(BoardState state, Move move) {
    throw UnimplementedError('Faz 1: hamle doğrulama');
  }

  /// [move]'u uygular ve yeni durumu döndürür. Yasadışıysa
  /// [IllegalMoveException] atar. Mevcut [state] değişmez.
  static BoardState applyMove(BoardState state, Move move) {
    throw UnimplementedError('Faz 1: hamle uygulama + kazanan tespiti (§6)');
  }
}
