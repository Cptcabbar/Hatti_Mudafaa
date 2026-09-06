import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('senaryo: Oyuncu 1 d-hattından ilerleyip kazanır', () {
    var state = buildState();
    const script = [
      'd2', 'e7', // p1, p2
      'd3', 'e6',
      'd4', 'e5',
      'd5', 'e4',
      'd6', 'e3',
      'd7', // p1 kazanır
    ];
    for (final token in script) {
      expect(state.isOver, isFalse);
      state = Rules.applyMove(state, Move.parse(token));
    }
    expect(state.winner, Player.p1);
    expect(state.ply, script.length);
  });

  test('rastgele kendi kendine oyun: hiç çökmez, her canlı durumda hamle var',
      () {
    final rng = Random(42);
    for (var game = 0; game < 25; game++) {
      var state = BoardState.initial();
      var steps = 0;
      while (!state.isOver && steps < 500) {
        final moves = Rules.legalMoves(state);
        expect(
          moves,
          isNotEmpty,
          reason: 'canlı durumda yasal hamle yok:\n$state',
        );
        final move = moves[rng.nextInt(moves.length)];

        // ara sıra: seçilen hamle gerçekten yasal listede mi + JSON round-trip
        if (steps % 40 == 0) {
          expect(Rules.isLegal(state, move), isTrue);
          final back = BoardState.fromJson(state.toJson());
          expect(back.toJson(), equals(state.toJson()));
        }

        state = Rules.applyMove(state, move, validate: false);
        steps++;
      }
      if (state.isOver) {
        expect(state.winner, isNotNull);
        // kazanan askeri gerçekten hedef satırda
        expect(
          state.pawnOf(state.winner!).row,
          state.goalRowOf(state.winner!),
        );
      }
    }
  });

  test('GameRecord ile bir oyunu baştan sona yeniden oynatma', () {
    final record = GameRecord.parse(
      config: GameConfig.v1,
      movesText: 'd2 e7 d3 e6 d4 e5 d5 e4 d6 e3 d7',
    );
    var state = record.initialState();
    for (final move in record.moves) {
      state = Rules.applyMove(state, move);
    }
    expect(state.winner, Player.p1);
  });
}
