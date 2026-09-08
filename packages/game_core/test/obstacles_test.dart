import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('ObstacleField.roll', () {
    test('v1 arazisinde engel karesi yok', () {
      expect(ObstacleField.roll(GameConfig.v1, Random(1)), isEmpty);
    });

    test('Geniş Arazi: sayı 2–4, benzersiz, başlangıç kareleri dışında', () {
      final config = GameConfig.wideTerrain;
      for (var seed = 0; seed < 200; seed++) {
        final field = ObstacleField.roll(config, Random(seed));
        expect(field.length, inInclusiveRange(2, 4), reason: 'seed $seed');
        expect(field.contains(config.startP1), isFalse);
        expect(field.contains(config.startP2), isFalse);
      }
    });

    test('yalnız izinli satırlarda: hedef satır + bir önü hariç (9×9 → r 2..6)',
        () {
      for (var seed = 0; seed < 200; seed++) {
        final field = ObstacleField.roll(GameConfig.wideTerrain, Random(seed));
        for (final sq in field) {
          expect(sq.row, inInclusiveRange(2, 6), reason: 'seed $seed → $sq');
        }
      }
    });

    test('yerleşim sonrası iki asker de hedefine ulaşabilir', () {
      final config = GameConfig.wideTerrain;
      for (var seed = 0; seed < 200; seed++) {
        final state = BoardState.initial(
          config,
          ObstacleField.roll(config, Random(seed)),
        );
        expect(
          Pathfinding.hasPathToRow(state, state.pawnP1, state.goalRowOf(Player.p1)),
          isTrue,
          reason: 'seed $seed P1',
        );
        expect(
          Pathfinding.hasPathToRow(state, state.pawnP2, state.goalRowOf(Player.p2)),
          isTrue,
          reason: 'seed $seed P2',
        );
      }
    });

    test('aynı tohum → aynı düzen (deterministik)', () {
      final a = ObstacleField.roll(GameConfig.wideTerrain, Random(42));
      final b = ObstacleField.roll(GameConfig.wideTerrain, Random(42));
      expect(a, equals(b));
    });

    test('farklı tohumlar en az bir farklı düzen üretir', () {
      final layouts = {
        for (var seed = 0; seed < 12; seed++)
          ObstacleField.roll(GameConfig.wideTerrain, Random(seed))
              .map((s) => s.toString())
              .toList()
            ..sort(),
      };
      expect(layouts.length, greaterThan(1));
    });
  });

  group('Rules.pawnMoves — engel kareleri', () {
    test('engel karesine adım atılamaz', () {
      final s = buildState(obstacles: ['d2']);
      expect(stepTargets(s), isNot(contains('d2')));
      expect(stepTargets(s), contains('c1'));
      expect(stepTargets(s), contains('e1'));
    });

    test('düz atlamada arka kare engelse çapraza düşer', () {
      // d3 (p1) → d4 (p2) → arkası d5 engel: düz atlama kapalı, çapraz açık
      final s = buildState(p1: 'd3', p2: 'd4', obstacles: ['d5']);
      final t = stepTargets(s);
      expect(t, isNot(contains('d5')));
      expect(t, contains('c4'));
      expect(t, contains('e4'));
    });

    test('çapraz atlama hedefi engelse elenir', () {
      // düz atlama kenar engeliyle kapalı, bir çapraz engel karesi
      final s = buildState(
        p1: 'd3',
        p2: 'd4',
        barriers: ['Md4h'], // d4↔d5 kapalı
        obstacles: ['c4'],
      );
      final t = stepTargets(s);
      expect(t, isNot(contains('d5')));
      expect(t, isNot(contains('c4')));
      expect(t, contains('e4'));
    });
  });

  group('Pathfinding — engel kareleri duvar', () {
    test('öne konan engel karesi yolu bir kare dolaştırır (+1)', () {
      final s = buildState(obstacles: ['d2']);
      expect(Pathfinding.shortestDistanceToRow(s, Square.parse('d1'), 6), 7);
    });

    test('engel kareleriyle tamamen çevrelenmiş kare → null', () {
      // c3 = (2,2): dört komşusu engel
      final s = buildState(obstacles: ['c4', 'c2', 'b3', 'd3']);
      expect(
        Pathfinding.shortestDistanceToRow(s, Square.parse('c3'), 6),
        isNull,
      );
    });
  });

  group('Rules.canPlaceBarrier — engel karesiyle etkileşim', () {
    test('engel karesi + engel birlikte yolu kapatırsa yasadışı', () {
      // c1 ve e1 engel karesi → d1'in tek çıkışı d2. O geçişi kapatan mayın
      // (Md1h → d1↔d2) yol kapatma yasağına takılmalı.
      final s = buildState(obstacles: ['c1', 'e1']);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Md1h')), isFalse);
      // Kıyas: engel kareleri olmadan aynı mayın serbest.
      final open = buildState();
      expect(Rules.canPlaceBarrier(open, Barrier.parse('Md1h')), isTrue);
    });
  });
}
