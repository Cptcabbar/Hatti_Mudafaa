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
