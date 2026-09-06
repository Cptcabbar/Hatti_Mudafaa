import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameConfig', () {
    test('v1 varsayılanları docs/rules.md §8 ile uyumlu', () {
      const c = GameConfig.v1;
      expect(c.boardSize, 7);
      expect(c.armoryPoints, 8);
      expect(c.mineCost, 1);
      expect(c.wireCost, 2);
      expect(c.startP1, Square.parse('d1'));
      expect(c.startP2, Square.parse('d7'));
    });

    test('JSON round-trip', () {
      final c = GameConfig.v1.copyWith(boardSize: 9, armoryPoints: 10);
      final back = GameConfig.fromJson(c.toJson());
      expect(back.boardSize, 9);
      expect(back.armoryPoints, 10);
      expect(back.startP1, c.startP1);
    });

    test('sınır kontrolleri', () {
      const c = GameConfig.v1;
      expect(c.isSquareInBounds(Square.parse('a1')), isTrue);
      expect(c.isSquareInBounds(Square.parse('g7')), isTrue);
      expect(c.isSquareInBounds(const Square(7, 0)), isFalse);
      // pivot aralığı a–f × 1–6
      expect(c.isPivotInBounds(Square.parse('f6')), isTrue);
      expect(c.isPivotInBounds(Square.parse('g6')), isFalse);
      expect(c.isPivotInBounds(Square.parse('f7')), isFalse);
    });
  });

  group('BoardState', () {
    test('initial: doğru başlangıç', () {
      final s = BoardState.initial();
      expect(s.pawnP1, Square.parse('d1'));
      expect(s.pawnP2, Square.parse('d7'));
      expect(s.turn, Player.p1);
      expect(s.armoryP1, 8);
      expect(s.armoryP2, 8);
      expect(s.ply, 0);
      expect(s.isOver, isFalse);
      expect(s.goalRowOf(Player.p1), 6);
      expect(s.goalRowOf(Player.p2), 0);
    });

    test('kapalı kenar indeksi engellerden kuruluyor', () {
      final s = BoardState.initial().copyWith(
        barriers: [Barrier.parse('Wc3h')],
      );
      expect(s.isEdgeBlocked(Square.parse('c3'), Square.parse('c4')), isTrue);
      expect(s.isEdgeBlocked(Square.parse('d3'), Square.parse('d4')), isTrue);
      expect(s.isEdgeBlocked(Square.parse('e3'), Square.parse('e4')), isFalse);
    });

    test('JSON round-trip', () {
      final s = BoardState.initial().copyWith(
        pawnP1: Square.parse('d3'),
        barriers: [Barrier.parse('Wc3h'), Barrier.parse('Mf1v')],
        turn: Player.p2,
        armoryP1: 6,
        ply: 3,
      );
      final back = BoardState.fromJson(s.toJson());
      expect(back.pawnP1, Square.parse('d3'));
      expect(back.barriers, hasLength(2));
      expect(back.turn, Player.p2);
      expect(back.armoryP1, 6);
      expect(back.ply, 3);
      expect(back.isEdgeBlocked(Square.parse('c3'), Square.parse('c4')), isTrue);
    });
  });

  group('GameRecord', () {
    test('movesText round-trip', () {
      final r = GameRecord.parse(
        config: GameConfig.v1,
        movesText: 'd2 Wc3h e5 Mf1v',
      );
      expect(r.moves, hasLength(4));
      expect(r.moves[0], isA<StepMove>());
      expect(r.moves[1], isA<PlaceBarrierMove>());
      expect(r.movesText(), 'd2 Wc3h e5 Mf1v');
    });

    test('JSON round-trip', () {
      final r = GameRecord.parse(config: GameConfig.v1, movesText: 'd2 e5');
      final back = GameRecord.fromJson(r.toJson());
      expect(back.movesText(), 'd2 e5');
      expect(back.config.boardSize, 7);
    });
  });
}
