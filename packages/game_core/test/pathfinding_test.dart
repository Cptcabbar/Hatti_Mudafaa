import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('Pathfinding.shortestDistanceToRow', () {
    test('boş tahta: d1 → 7. satır = 6 adım', () {
      final s = buildState();
      expect(Pathfinding.shortestDistanceToRow(s, Square.parse('d1'), 6), 6);
    });

    test('zaten hedef satırdaysa 0', () {
      final s = buildState();
      expect(Pathfinding.shortestDistanceToRow(s, Square.parse('a7'), 6), 0);
    });

    test('öne konan tek mayın yolu tıkamaz, bir kare dolaştırır (+1)', () {
      // d1 önündeki dikey geçişi kapat: d1↔d2
      final s = buildState(barriers: ['Md1h']);
      expect(Pathfinding.shortestDistanceToRow(s, Square.parse('d1'), 6), 7);
    });

    test('tamamen çevrelenmiş kare → null', () {
      // b2 = (1,1): kuzey b2↔b3, güney b1↔b2, doğu b2↔c2, batı a2↔b2
      final s = buildState(
        barriers: ['Mb2h', 'Mb1h', 'Mb2v', 'Ma2v'],
      );
      expect(
        Pathfinding.shortestDistanceToRow(s, Square.parse('b2'), 6),
        isNull,
      );
    });
  });

  group('Pathfinding.shortestPathToRow', () {
    test('boş tahta: d1 → 7. satır, 7 kare (d1..d7), her adım ortogonal', () {
      final s = buildState();
      final path = Pathfinding.shortestPathToRow(s, Square.parse('d1'), 6);
      expect(path, isNotNull);
      expect(path!.first, Square.parse('d1'));
      expect(path.last.row, 6);
      expect(path.length, 7);
      for (var i = 1; i < path.length; i++) {
        expect(path[i - 1].isOrthogonalNeighbor(path[i]), isTrue);
        expect(s.isEdgeBlocked(path[i - 1], path[i]), isFalse);
      }
    });

    test('zaten hedef satırdaysa tek elemanlı yol', () {
      final s = buildState();
      expect(
        Pathfinding.shortestPathToRow(s, Square.parse('a7'), 6),
        [Square.parse('a7')],
      );
    });

    test('yolu tıkalı kare → null', () {
      final s = buildState(barriers: ['Mb2h', 'Mb1h', 'Mb2v', 'Ma2v']);
      expect(
        Pathfinding.shortestPathToRow(s, Square.parse('b2'), 6),
        isNull,
      );
    });

    test('uzunluk her zaman shortestDistanceToRow + 1', () {
      final s = buildState(barriers: ['Md1h']);
      final d = Pathfinding.shortestDistanceToRow(s, Square.parse('d1'), 6)!;
      final path = Pathfinding.shortestPathToRow(s, Square.parse('d1'), 6)!;
      expect(path.length, d + 1);
    });
  });

  group('Pathfinding.hasPathToRow', () {
    test('boş tahta: her iki askerin de yolu var', () {
      final s = buildState();
      expect(Pathfinding.hasPathToRow(s, s.pawnP1, s.goalRowOf(Player.p1)),
          isTrue);
      expect(Pathfinding.hasPathToRow(s, s.pawnP2, s.goalRowOf(Player.p2)),
          isTrue);
    });

    test('tahtayı ikiye bölen tam duvar → yol yok', () {
      // 3–4 satır boşluğunu boydan boya kapat
      final s = buildState(
        barriers: ['Wa3h', 'Wc3h', 'We3h', 'Mg3h'],
      );
      expect(
        Pathfinding.hasPathToRow(s, Square.parse('d1'), 6),
        isFalse,
      );
    });
  });
}
