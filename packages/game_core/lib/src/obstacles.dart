import 'dart:math';

import 'board_state.dart';
import 'config.dart';
import 'coord.dart';
import 'pathfinding.dart';

/// Oyun başında tahtaya konan **kare-kapatan engelleri** (§2.1) üretir —
/// "Geniş Arazi" ağaçları gibi. Tek doğruluk kaynağı `docs/rules.md` §2.1.
///
/// Saf hesap: aynı [config] + aynı [Random] → aynı sonuç. Yerel oyun ve
/// (ileride) online, engel düzenini bu fonksiyonla üretip paylaşır.
abstract final class ObstacleField {
  /// [config.obstacleCountMin]..[config.obstacleCountMax] adet engel karesi.
  ///
  /// Kurallar:
  /// - Her oyuncunun hedef satırı **ve bir önündeki satır** dışarıda
  ///   (0-tabanlı izinli aralık: `2 .. boardSize - 3`).
  /// - Başlangıç kareleri dışarıda; her kare benzersiz.
  /// - Bir aday ancak eklendikten sonra **iki asker de** hedefine ulaşabiliyorsa
  ///   kabul edilir (BFS; oyunun temel invaryantı).
  ///
  /// `obstacleCountMax <= 0` ise boş küme (v1).
  static Set<Square> roll(GameConfig config, Random rng) {
    final maxCount = config.obstacleCountMax;
    if (maxCount <= 0) return const {};

    final size = config.boardSize;
    const minRow = 2; // P2 hedefi (0) + bir önü (1) hariç
    final maxRow = size - 3; // P1 hedefi (size-1) + bir önü (size-2) hariç
    if (maxRow < minRow) return const {};

    final starts = {config.startP1, config.startP2};
    final candidates = <Square>[
      for (var c = 0; c < size; c++)
        for (var r = minRow; r <= maxRow; r++)
          if (!starts.contains(Square(c, r))) Square(c, r),
    ]..shuffle(rng);

    final minCount = config.obstacleCountMin.clamp(0, maxCount);
    final target = minCount + rng.nextInt(maxCount - minCount + 1);
    if (target <= 0) return const {};

    final chosen = <Square>{};
    for (final sq in candidates) {
      if (chosen.length >= target) break;
      final probe = BoardState.initial(config, {...chosen, sq});
      final ok = Pathfinding.hasPathToRow(
            probe,
            probe.pawnP1,
            probe.goalRowOf(Player.p1),
          ) &&
          Pathfinding.hasPathToRow(
            probe,
            probe.pawnP2,
            probe.goalRowOf(Player.p2),
          );
      if (ok) chosen.add(sq);
    }
    return chosen;
  }
}
