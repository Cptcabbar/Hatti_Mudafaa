import 'dart:collection';

import 'board_state.dart';
import 'coord.dart';

/// Tahta üzerinde en kısa yol / erişilebilirlik hesapları.
///
/// `docs/rules.md` §5.3/4 "yol kapatma yasağı" ve `game_ai` değerlendirme
/// fonksiyonu buna dayanır. Grafik yalnızca **statik engelleri** dikkate alır:
/// kenar kapatan mayın/tel **ve** kare kapatan engeller (§2.1). Rakip asker
/// (atlama) hesaba katılmaz — piyonlar yoldan çekilebilir, engeller kalıcıdır.
abstract final class Pathfinding {
  /// [from] karesinden [goalRow] satırındaki herhangi bir kareye giden en kısa
  /// yolun adım sayısı; yol yoksa `null`.
  static int? shortestDistanceToRow(BoardState state, Square from, int goalRow) {
    final size = state.config.boardSize;
    if (from.row == goalRow) return 0;

    final visited = List.generate(
      size,
      (_) => List<bool>.filled(size, false),
      growable: false,
    );
    visited[from.col][from.row] = true;

    final queue = Queue<Square>()..add(from);
    var frontierDist = 0;
    var frontierEnd = 1;
    var processed = 0;

    while (queue.isNotEmpty) {
      final sq = queue.removeFirst();
      final nextDist = frontierDist + 1;

      for (final dir in Direction.values) {
        final next = sq.step(dir);
        if (next.col < 0 || next.col >= size || next.row < 0 || next.row >= size) {
          continue;
        }
        if (visited[next.col][next.row]) continue;
        if (state.isEdgeBlocked(sq, next)) continue;
        if (state.isObstacle(next)) continue;
        if (next.row == goalRow) return nextDist;
        visited[next.col][next.row] = true;
        queue.add(next);
      }

      if (++processed == frontierEnd) {
        frontierDist = nextDist;
        frontierEnd = processed + queue.length;
      }
    }
    return null;
  }

  /// [from]'dan [goalRow]'a en kısa yollardan biri — kareler dizisi, [from]
  /// dahil, hedef satırdaki varış karesi dahil. Yol yoksa `null`.
  ///
  /// `game_ai` engel adaylarını "yola değen" olanlarla sınırlamak için kullanır.
  static List<Square>? shortestPathToRow(
    BoardState state,
    Square from,
    int goalRow,
  ) {
    final size = state.config.boardSize;
    if (from.row == goalRow) return [from];

    final visited = List.generate(
      size,
      (_) => List<bool>.filled(size, false),
      growable: false,
    );
    visited[from.col][from.row] = true;
    final prev = <Square, Square>{};

    final queue = Queue<Square>()..add(from);
    while (queue.isNotEmpty) {
      final sq = queue.removeFirst();
      for (final dir in Direction.values) {
        final next = sq.step(dir);
        if (next.col < 0 || next.col >= size || next.row < 0 || next.row >= size) {
          continue;
        }
        if (visited[next.col][next.row]) continue;
        if (state.isEdgeBlocked(sq, next)) continue;
        if (state.isObstacle(next)) continue;
        prev[next] = sq;
        if (next.row == goalRow) {
          final path = <Square>[next];
          var cur = next;
          while (cur != from) {
            cur = prev[cur]!;
            path.add(cur);
          }
          return path.reversed.toList(growable: false);
        }
        visited[next.col][next.row] = true;
        queue.add(next);
      }
    }
    return null;
  }

  /// [from]'dan [goalRow]'a en az bir yol var mı? ("yol kapatma yasağı" kontrolü)
  static bool hasPathToRow(BoardState state, Square from, int goalRow) {
    final size = state.config.boardSize;
    if (from.row == goalRow) return true;

    final visited = List.generate(
      size,
      (_) => List<bool>.filled(size, false),
      growable: false,
    );
    visited[from.col][from.row] = true;

    final stack = <Square>[from];
    while (stack.isNotEmpty) {
      final sq = stack.removeLast();
      for (final dir in Direction.values) {
        final next = sq.step(dir);
        if (next.col < 0 || next.col >= size || next.row < 0 || next.row >= size) {
          continue;
        }
        if (visited[next.col][next.row]) continue;
        if (state.isEdgeBlocked(sq, next)) continue;
        if (state.isObstacle(next)) continue;
        if (next.row == goalRow) return true;
        visited[next.col][next.row] = true;
        stack.add(next);
      }
    }
    return false;
  }
}
