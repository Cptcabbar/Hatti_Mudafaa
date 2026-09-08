import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_ai/game_ai.dart';
import 'package:game_core/game_core.dart';
import 'package:hatti_mudafaa/game/board_metrics.dart';
import 'package:hatti_mudafaa/game/game_controller.dart';

void main() {
  final metrics = BoardMetrics(boardSize: 7, side: 700);

  void humanStepForward(GameController c) {
    final target = c.legalStepTargets.first;
    c.tapBoard(metrics.cellCenter(target), metrics);
  }

  test('yapay zekaya karşı: insan oynar → AI düşünür → hamlesini yapar', () {
    fakeAsync((async) {
      final c = GameController(
        timed: false,
        aiDifficulty: AiDifficulty.medium,
        aiSeed: 7,
      );
      addTearDown(c.dispose);

      expect(c.vsAi, isTrue);
      expect(c.aiThinking, isFalse);
      expect(c.turn, Player.p1);

      humanStepForward(c);

      expect(c.state.ply, 1);
      expect(c.turn, Player.p2);
      expect(c.aiThinking, isTrue, reason: 'sıra AI\'ya geçince düşünmeye başlar');
      expect(c.acceptsInput, isFalse);

      // Düşünme penceresi 3-5 sn; 6 sn akıtınca AI oynamış olmalı.
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      expect(c.aiThinking, isFalse);
      expect(c.turn, Player.p1, reason: 'AI oynadı, sıra insana döndü');
      expect(c.state.ply, 2);
      expect(c.acceptsInput, isTrue);
    });
  });

  test('AI hamlesi en az ~3 sn sonra gelir (anında değil)', () {
    fakeAsync((async) {
      final c = GameController(
        timed: false,
        aiDifficulty: AiDifficulty.hard,
        aiSeed: 1,
      );
      addTearDown(c.dispose);

      humanStepForward(c);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();

      expect(c.aiThinking, isTrue, reason: '2 sn sonra hâlâ düşünüyor olmalı');
      expect(c.state.ply, 1);

      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(c.state.ply, 2);
    });
  });

  test('AI düşünürken "geri al" kilitli; hamleden sonra iki adım geri alır', () {
    fakeAsync((async) {
      final c = GameController(
        timed: false,
        aiDifficulty: AiDifficulty.easy,
        aiSeed: 3,
      );
      addTearDown(c.dispose);

      humanStepForward(c);
      expect(c.canUndo, isFalse, reason: 'AI düşünürken geri al yok');
      c.undo(); // yok sayılmalı
      expect(c.state.ply, 1);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(c.state.ply, 2);
      expect(c.canUndo, isTrue);

      c.undo(); // hem AI hem insan hamlesini geri al
      expect(c.state.ply, 0);
      expect(c.turn, Player.p1);
      expect(c.aiThinking, isFalse, reason: 'geri alınca AI yeniden düşünmez');
    });
  });

  test('Geniş Arazi: yapay zeka 9×9 + ağaçlarla yasal hamle yapar', () {
    fakeAsync((async) {
      final m9 = BoardMetrics(boardSize: 9, side: 900);
      final c = GameController(
        config: GameConfig.wideTerrain,
        timed: false,
        aiDifficulty: AiDifficulty.hard,
        aiSeed: 2,
        obstacleSeed: 4,
      );
      addTearDown(c.dispose);

      expect(c.state.config.boardSize, 9);
      expect(c.state.obstacles.length, inInclusiveRange(2, 4));

      c.tapBoard(m9.cellCenter(c.legalStepTargets.first), m9);
      expect(c.state.ply, 1);
      expect(c.aiThinking, isTrue);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      expect(c.aiThinking, isFalse);
      expect(c.state.ply, 2);
      // AI hamlesi geçerli ve ağaç karesine girmedi
      expect(c.state.obstacles.contains(c.state.pawnP2), isFalse);
    });
  });

  test('iki kişilik oyunda AI hiç devreye girmez', () {
    fakeAsync((async) {
      final c = GameController(timed: false);
      addTearDown(c.dispose);

      expect(c.vsAi, isFalse);
      humanStepForward(c);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      expect(c.aiThinking, isFalse);
      expect(c.turn, Player.p2, reason: 'sıra P2 insanında bekler');
      expect(c.state.ply, 1);
    });
  });
}
