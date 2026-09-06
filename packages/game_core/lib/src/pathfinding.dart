import 'board_state.dart';
import 'coord.dart';

/// Tahta üzerinde en kısa yol / erişilebilirlik hesapları.
///
/// **Faz 1'de uygulanacak.** `docs/rules.md` §5.3/4 "yol kapatma yasağı" ve
/// `game_ai` değerlendirme fonksiyonu buna dayanır.
abstract final class Pathfinding {
  /// [from] karesinden [goalRow] satırındaki herhangi bir kareye giden en kısa
  /// yolun adım sayısı; yol yoksa `null`.
  ///
  /// Engelleri [state] üzerinden dikkate alır; rakip askeri (atlama) hesaba
  /// katmaz — yalnızca statik engel grafiği üzerinde BFS.
  static int? shortestDistanceToRow(BoardState state, Square from, int goalRow) {
    throw UnimplementedError('Faz 1: BFS ile en kısa mesafe');
  }

  /// [from]'dan [goalRow]'a en az bir yol var mı? ("yol kapatma yasağı" kontrolü)
  static bool hasPathToRow(BoardState state, Square from, int goalRow) {
    throw UnimplementedError('Faz 1: erişilebilirlik BFS');
  }
}
