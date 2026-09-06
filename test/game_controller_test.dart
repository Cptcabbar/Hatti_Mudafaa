import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:hatti_mudafaa/game/board_metrics.dart';
import 'package:hatti_mudafaa/game/game_controller.dart';

void main() {
  final metrics = BoardMetrics(boardSize: 7, side: 700); // hücre = 100

  group('hareket modu', () {
    test('başlangıç: yasal hedefler c1/e1/d2, geri alınamaz', () {
      final c = GameController();
      expect(
        c.legalStepTargets.map((s) => s.toString()).toSet(),
        {'c1', 'e1', 'd2'},
      );
      expect(c.canUndo, isFalse);
      expect(c.mode, InteractionMode.move);
    });

    test('yasal kareye dokunmak piyonu oynatır ve sırayı çevirir', () {
      final c = GameController();
      c.tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
      expect(c.state.pawnP1, Square.parse('d2'));
      expect(c.state.turn, Player.p2);
      expect(c.canUndo, isTrue);
    });

    test('yasadışı kareye dokunmak bir şey değiştirmez', () {
      final c = GameController();
      c.tapBoard(metrics.cellCenter(Square.parse('a4')), metrics);
      expect(c.state.pawnP1, Square.parse('d1'));
      expect(c.state.turn, Player.p1);
    });

    test('geri al başlangıca döndürür', () {
      final c = GameController()
        ..tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
      c.undo();
      expect(c.state.pawnP1, Square.parse('d1'));
      expect(c.canUndo, isFalse);
    });
  });

  group('engel modu', () {
    test('mayın modunda dokunmak önizleme kurar', () {
      final c = GameController()..setMode(InteractionMode.mine);
      c.tapBoard(const Offset(350, 500), metrics);
      expect(c.preview, isNotNull);
      expect(c.preview!.isMine, isTrue);
    });

    test('onayla: engel konur, puan düşer, sıra döner, moda geri', () {
      final c = GameController()..setMode(InteractionMode.mine);
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
      final c = GameController()..setMode(InteractionMode.wire);
      c.tapBoard(const Offset(350, 350), metrics);
      final before = c.preview!.orientation;
      c.rotatePreview();
      expect(c.preview!.orientation, isNot(before));
    });

    test('cephanelik biterse mayın modu satın alınamaz', () {
      final c = GameController(
        config: GameConfig.v1.copyWith(armoryPoints: 0),
      );
      expect(c.canAfford(BarrierType.mine), isFalse);
      expect(c.canAfford(BarrierType.wire), isFalse);
    });
  });

  test('restart temiz duruma döner', () {
    final c = GameController()
      ..tapBoard(metrics.cellCenter(Square.parse('d2')), metrics);
    c.restart();
    expect(c.state.pawnP1, Square.parse('d1'));
    expect(c.state.ply, 0);
    expect(c.canUndo, isFalse);
  });
}
