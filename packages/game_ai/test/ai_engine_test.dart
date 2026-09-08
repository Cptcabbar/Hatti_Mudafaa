import 'dart:math';

import 'package:game_ai/game_ai.dart';
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

/// [state]'ten başlayıp rastgele yasal hamlelerle en çok [plies] tur ilerler.
BoardState _randomAdvance(BoardState state, Random rng, int plies) {
  var s = state;
  for (var i = 0; i < plies && !s.isOver; i++) {
    final moves = Rules.legalMoves(s);
    if (moves.isEmpty) break;
    s = Rules.applyMove(s, moves[rng.nextInt(moves.length)], validate: false);
  }
  return s;
}

/// İki motor arası tam oyun. Kazanan Player, ya da ply sınırına takılırsa null.
Future<Player?> _playGame(
  AiEngine p1,
  AiEngine p2, {
  int maxPlies = 160,
}) async {
  var s = BoardState.initial();
  for (var i = 0; i < maxPlies && !s.isOver; i++) {
    final engine = s.turn == Player.p1 ? p1 : p2;
    final move =
        await engine.chooseMove(s, budget: const Duration(milliseconds: 120));
    s = Rules.applyMove(s, move, validate: false);
  }
  return s.winner;
}

void main() {
  test('AiDifficulty üç seviye tanımlı', () {
    expect(AiDifficulty.values, hasLength(3));
    expect(AiDifficulty.values,
        containsAll([AiDifficulty.easy, AiDifficulty.medium, AiDifficulty.hard]));
  });

  group('Evaluation', () {
    test('kazanan durum çok yüksek, kaybeden çok düşük', () {
      final won = BoardState.initial().copyWith(winner: Player.p1);
      expect(Evaluation.score(won, Player.p1), greaterThan(Evaluation.win ~/ 2));
      expect(Evaluation.score(won, Player.p2), lessThan(-Evaluation.win ~/ 2));
    });

    test('hedefe daha yakın olmak daha iyi', () {
      final far = BoardState.initial();
      final near = far.copyWith(pawnP1: Square.parse('d6'));
      expect(
        Evaluation.score(near, Player.p1),
        greaterThan(Evaluation.score(far, Player.p1)),
      );
    });

    test('başlangıç simetrik (≈0)', () {
      final s = BoardState.initial();
      expect(Evaluation.score(s, Player.p1).abs(), lessThanOrEqualTo(3));
    });
  });

  group('NegamaxEngine — hamle geçerliliği', () {
    for (final diff in AiDifficulty.values) {
      test('$diff hiçbir zaman yasadışı hamle üretmez (40 rastgele konum)',
          () async {
        final rng = Random(diff.index + 7);
        final engine = NegamaxEngine(diff, seed: 99);
        for (var t = 0; t < 40; t++) {
          final s = _randomAdvance(BoardState.initial(), rng, rng.nextInt(24));
          if (s.isOver) continue;
          final move = await engine.chooseMove(
            s,
            budget: const Duration(milliseconds: 150),
          );
          expect(
            Rules.isLegal(s, move),
            isTrue,
            reason: 'konum: $s\nhamle: ${move.toNotation()}',
          );
        }
      });
    }

    test('tek yasal hamle varsa onu seçer', () async {
      final s = BoardState(
        config: GameConfig.v1,
        pawnP1: Square.parse('b2'),
        pawnP2: Square.parse('g7'),
        barriers: [
          Barrier.parse('Mb1h'),
          Barrier.parse('Mb2v'),
          Barrier.parse('Ma2v'),
        ],
        turn: Player.p1,
        armoryP1: 0,
        armoryP2: 0,
      );
      final legal = Rules.legalMoves(s);
      expect(legal, hasLength(1));
      final move = await NegamaxEngine(AiDifficulty.hard)
          .chooseMove(s, budget: const Duration(milliseconds: 100));
      expect(move, legal.single);
    });
  });

  group('NegamaxEngine — bütçe', () {
    test('hard bütçeyi aşırı aşmaz (~3x tolerans)', () async {
      final s = _randomAdvance(BoardState.initial(), Random(3), 6);
      final sw = Stopwatch()..start();
      await NegamaxEngine(AiDifficulty.hard)
          .chooseMove(s, budget: const Duration(milliseconds: 300));
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('NegamaxEngine — Geniş Arazi (9×9 + ağaçlar)', () {
    BoardState wideStart(int seed) => BoardState.initial(
          GameConfig.wideTerrain,
          ObstacleField.roll(GameConfig.wideTerrain, Random(seed)),
        );

    for (final diff in AiDifficulty.values) {
      test('$diff: 9×9 + ağaçlarda yasal hamle + bütçe içinde (8 açılış)',
          () async {
        final engine = NegamaxEngine(diff, seed: 5);
        var maxMs = 0;
        for (var seed = 0; seed < 8; seed++) {
          final s = _randomAdvance(wideStart(seed), Random(seed + 30), 10);
          if (s.isOver) continue;
          final sw = Stopwatch()..start();
          final move = await engine.chooseMove(
            s,
            budget: const Duration(milliseconds: 500),
          );
          sw.stop();
          maxMs = maxMs < sw.elapsedMilliseconds ? sw.elapsedMilliseconds : maxMs;
          expect(Rules.isLegal(s, move), isTrue, reason: 'konum: $s');
        }
        // ignore: avoid_print
        print('$diff 9×9 en yüksek hamle süresi: ${maxMs}ms');
        expect(maxMs, lessThan(1500), reason: '$diff çok yavaş');
      });
    }
  });

  group('NegamaxEngine — güç sıralaması', () {
    test('zor, kolaya karşı oyunların büyük çoğunluğunu kazanır', () async {
      var hardWins = 0;
      var played = 0;
      for (var g = 0; g < 14; g++) {
        final hard = NegamaxEngine(AiDifficulty.hard, seed: g);
        final easy = NegamaxEngine(AiDifficulty.easy, seed: 100 + g);
        final hardIsP1 = g.isEven;
        final winner = hardIsP1
            ? await _playGame(hard, easy)
            : await _playGame(easy, hard);
        if (winner == null) continue;
        played++;
        if ((winner == Player.p1) == hardIsP1) hardWins++;
      }
      expect(played, greaterThanOrEqualTo(10));
      expect(hardWins / played, greaterThanOrEqualTo(0.75),
          reason: '$hardWins / $played');
    });
  });
}
