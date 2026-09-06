import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('pawnMoves — temel hareket (§4.1)', () {
    test('başlangıç d1: 3 hamle (c1, e1, d2)', () {
      expect(stepTargets(buildState()), {'c1', 'e1', 'd2'});
    });

    test('merkez d4: 4 hamle', () {
      expect(stepTargets(buildState(p1: 'd4')), {'c4', 'e4', 'd3', 'd5'});
    });

    test('engel bir yönü kapatır', () {
      // d4↔e4 kapalı (dikey engel d4)
      final s = buildState(p1: 'd4', barriers: ['Md4v']);
      expect(stepTargets(s), {'c4', 'd3', 'd5'});
    });
  });

  group('pawnMoves — atlama (§4.2)', () {
    test('düz atlama açıkken rakibin üzerinden atlar', () {
      final s = buildState(p1: 'd4', p2: 'd5');
      expect(stepTargets(s), {'c4', 'e4', 'd3', 'd6'});
    });

    test('düz atlama engelliyse iki çapraz açılır', () {
      // d5↔d6 kapalı
      final s = buildState(p1: 'd4', p2: 'd5', barriers: ['Md5h']);
      expect(stepTargets(s), {'c4', 'e4', 'd3', 'c5', 'e5'});
    });

    test('düz atlama tahta kenarıyla engelliyse çaprazlar açılır', () {
      // p1 d2, p2 d1 — güneye atlama tahta dışı
      final s = buildState(p1: 'd2', p2: 'd1');
      expect(stepTargets(s), {'c2', 'e2', 'd3', 'c1', 'e1'});
    });

    test('çaprazlardan biri engelliyse yalnız diğeri açılır', () {
      // p1 d2, p2 d1; c1↔d1 kapalı
      final s = buildState(p1: 'd2', p2: 'd1', barriers: ['Mc1v']);
      expect(stepTargets(s), {'c2', 'e2', 'd3', 'e1'});
    });
  });

  group('canPlaceBarrier / barrierMoves (§5.3)', () {
    test('çakışma yasak — aynı ve örten engeller', () {
      final s = buildState(barriers: ['Wc3h']);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Wc3h')), isFalse);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Mc3h')), isFalse);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Wd3h')), isFalse);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Wb3h')), isFalse);
    });

    test('tel + tel aynı pivotta dik kesişemez', () {
      final s = buildState(barriers: ['Wc3h']);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Wc3v')), isFalse);
    });

    test('mayın dik telle kesişebilir (farklı kenar)', () {
      final s = buildState(barriers: ['Wc3h']);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Mc3v')), isTrue);
    });

    test('yol kapatan engel yasadışı', () {
      final s = buildState(barriers: ['Wa3h', 'Wc3h', 'We3h']);
      expect(Rules.canPlaceBarrier(s, Barrier.parse('Mg3h')), isFalse);
      expect(barrierTargets(s), isNot(contains('Mg3h')));
    });

    test('cephanelik 1 puan → yalnız mayın önerilir', () {
      final s = buildState(armoryP1: 1);
      final moves = Rules.barrierMoves(s);
      expect(moves, isNotEmpty);
      expect(moves.every((m) => m.barrier.isMine), isTrue);
    });

    test('cephanelik 0 → engel hamlesi yok', () {
      final s = buildState(armoryP1: 0);
      expect(Rules.barrierMoves(s), isEmpty);
      expect(Rules.legalMoves(s), equals(Rules.pawnMoves(s)));
    });

    test('başlangıçta çok sayıda benzersiz engel yeri var', () {
      final targets = barrierTargets(buildState());
      expect(targets.length, greaterThan(100));
    });
  });

  group('applyMove', () {
    test('ilerleme: piyon, sıra ve ply güncellenir', () {
      final s = Rules.applyMove(buildState(), const StepMove(Square(3, 1)));
      expect(s.pawnP1, Square.parse('d2'));
      expect(s.turn, Player.p2);
      expect(s.ply, 1);
      expect(s.isOver, isFalse);
    });

    test('engel: cephanelikten doğru puan düşer, sıra döner', () {
      final s = Rules.applyMove(
        buildState(),
        PlaceBarrierMove(Barrier.parse('Wd3h')),
      );
      expect(s.barriers.map((b) => b.toNotation()), contains('Wd3h'));
      expect(s.armoryP1, 6); // 8 - 2
      expect(s.armoryP2, 8);
      expect(s.turn, Player.p2);
    });

    test('hedef satıra ulaşınca kazanan set edilir ve oyun biter', () {
      final s = buildState(p1: 'd6', p2: 'a1');
      final after = Rules.applyMove(s, const StepMove(Square(3, 6)));
      expect(after.winner, Player.p1);
      expect(after.isOver, isTrue);
    });

    test('yasadışı hamle IllegalMoveException atar', () {
      expect(
        () => Rules.applyMove(buildState(), const StepMove(Square(0, 0))),
        throwsA(isA<IllegalMoveException>()),
      );
    });

    test('oyun bittikten sonra hamle IllegalMoveException atar', () {
      final won = buildState(p1: 'd6', p2: 'a1');
      final over = Rules.applyMove(won, const StepMove(Square(3, 6)));
      expect(
        () => Rules.applyMove(over, const StepMove(Square(3, 5))),
        throwsA(isA<IllegalMoveException>()),
      );
    });

    test('validate:false yasal hamleyi doğrulamadan uygular', () {
      final s = Rules.applyMove(
        buildState(),
        const StepMove(Square(3, 1)),
        validate: false,
      );
      expect(s.pawnP1, Square.parse('d2'));
    });
  });
}
