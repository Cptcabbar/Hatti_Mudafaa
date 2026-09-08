import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:hatti_mudafaa/game/board_metrics.dart';
import 'package:hatti_mudafaa/game/game_controller.dart';

void main() {
  final metrics = BoardMetrics(boardSize: 7, side: 700); // hücre = 100

  GameController make({GameConfig? config}) =>
      GameController(config: config ?? GameConfig.v1, timed: false);

  group('hareket modu', () {
    test('başlangıç: yasal hedefler c1/e1/d2, geri alınamaz', () {
      final c = make();
      expect(
        c.legalStepTargets.map((s) => s.toString()).toSet(),
        {'c1', 'e1', 'd2'},
      );
      expect(c.canUndo, isFalse);
      expect(c.mode, InteractionMode.move);
    });

    test('yasal kareye dokunmak piyonu oynatır ve sırayı çevirir', () {
      final c = make();
      c.tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
      expect(c.state.pawnP1, Square.parse('d2'));
      expect(c.state.turn, Player.p2);
      expect(c.canUndo, isTrue);
    });

    test('yasadışı kareye dokunmak bir şey değiştirmez', () {
      final c = make();
      c.tapBoard(metrics.cellCenter(Square.parse('a4')), metrics);
      expect(c.state.pawnP1, Square.parse('d1'));
      expect(c.state.turn, Player.p1);
    });

    test('geri al başlangıca döndürür', () {
      final c = make()
        ..tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
      c.undo();
      expect(c.state.pawnP1, Square.parse('d1'));
      expect(c.canUndo, isFalse);
    });
  });

  group('engel modu', () {
    test('mayın modunda dokunmak önizleme kurar', () {
      final c = make()..setMode(InteractionMode.mine);
      c.tapBoard(const Offset(350, 500), metrics);
      expect(c.preview, isNotNull);
      expect(c.preview!.isMine, isTrue);
    });

    test('onayla: engel konur, puan düşer, sıra döner, moda geri', () {
      final c = make()..setMode(InteractionMode.mine);
      c.tapBoard(const Offset(350, 500), metrics);
      expect(c.canConfirmPreview, isTrue);
      c.confirmPreview();
      expect(c.state.barriers, hasLength(1));
      expect(c.state.armoryP1, 7);
      expect(c.state.turn, Player.p2);
      expect(c.mode, InteractionMode.move);
      expect(c.preview, isNull);
    });

    test('döndür önizlemenin yönünü çevirir', () {
      final c = make()..setMode(InteractionMode.wire);
      c.tapBoard(const Offset(350, 350), metrics);
      final before = c.preview!.orientation;
      c.rotatePreview();
      expect(c.preview!.orientation, isNot(before));
    });

    test('cephanelik biterse mayın modu satın alınamaz', () {
      final c = make(config: GameConfig.v1.copyWith(armoryPoints: 0));
      expect(c.canAfford(BarrierType.mine), isFalse);
      expect(c.canAfford(BarrierType.wire), isFalse);
    });
  });

  test('restart temiz duruma döner', () {
    final c = make()..tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
    c.restart();
    expect(c.state.pawnP1, Square.parse('d1'));
    expect(c.state.ply, 0);
    expect(c.canUndo, isFalse);
  });

  group('Geniş Arazi (wideTerrain)', () {
    test('başlangıç: 9×9, 11 kredi, 2–4 ağaç (izinli satırlarda)', () {
      final c = GameController(
        config: GameConfig.wideTerrain,
        timed: false,
        obstacleSeed: 1,
      );
      expect(c.state.config.boardSize, 9);
      expect(c.state.armoryP1, 11);
      expect(c.state.armoryP2, 11);
      expect(c.state.obstacles.length, inInclusiveRange(2, 4));
      for (final sq in c.state.obstacles) {
        expect(sq.row, inInclusiveRange(2, 6));
      }
    });

    test('restart ağaçları yeni konumlara taşır', () {
      final c = GameController(
        config: GameConfig.wideTerrain,
        timed: false,
        obstacleSeed: 7,
      );
      final layouts = <String>{};
      for (var i = 0; i < 8; i++) {
        layouts.add((c.state.obstacles.map((s) => s.toString()).toList()..sort())
            .join(','));
        c.restart();
      }
      expect(layouts.length, greaterThan(1));
    });

    test('v1 arazisinde ağaç yok', () {
      final c = make();
      expect(c.state.obstacles, isEmpty);
    });
  });

  group('süreli mod', () {
    test('süre dolunca sıradaki asker hedefe doğru otomatik ilerler', () async {
      final c = GameController(
        timed: true,
        turnDuration: const Duration(milliseconds: 400),
      );
      expect(c.turn, Player.p1);

      await Future<void>.delayed(const Duration(milliseconds: 900));
      c.dispose(); // sayacı durdur, daha fazla otomatik hamle olmasın

      expect(c.state.ply, greaterThanOrEqualTo(1));
      // p1'in ilk otomatik hamlesi hedefe en çok yaklaştıran adım: d1 → d2
      expect(c.state.pawnP1, Square.parse('d2'));
    });

    test('süreli mod kapalıyken sayaç sıfır', () {
      final c = make();
      expect(c.secondsLeft, 0);
      expect(c.turnFraction, 0);
    });
  });
}
