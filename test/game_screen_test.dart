import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:hatti_mudafaa/game/board_metrics.dart';
import 'package:hatti_mudafaa/game/game_controller.dart';
import 'package:hatti_mudafaa/ui/game_screen.dart';

void main() {
  /// Flame sahnesi yüklenip "Cephe hazırlanıyor" örtüsü kalkana kadar bekle.
  Future<void> settleScene(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Cephe hazırlanıyor').evaluate().isEmpty) return;
    }
  }

  testWidgets('oyun ekranı açılır: durum çubuğu + mod düğmeleri', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(timed: false)));
    await settleScene(tester);

    expect(find.text('Mavi oynuyor'), findsOneWidget);
    expect(find.text('Hareket'), findsOneWidget);
    expect(find.text('Mayın'), findsOneWidget);
    expect(find.text('Tel'), findsOneWidget);
    // engel modu seçilmeden Döndür/Onayla görünmez
    expect(find.text('Onayla'), findsNothing);
  });

  testWidgets('Mayın moduna geçince onay çubuğu belirir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(timed: false)));
    await settleScene(tester);

    await tester.tap(find.text('Mayın'));
    await tester.pump();

    expect(find.text('Döndür'), findsOneWidget);
    expect(find.text('Onayla'), findsOneWidget);
  });

  testWidgets('çıkış "×" önce onay ister; Vazgeç ekranda tutar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(timed: false)));
    await settleScene(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Oyundan çık'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Oyundan çık'), findsNothing);
    expect(find.text('Mavi oynuyor'), findsOneWidget); // hâlâ oyunda
  });

  testWidgets(
      'oyun bitince kazanma diyaloğu: "Ana menü" ekranı kapatır, "×" da çalışır',
      (tester) async {
    // Küçük tahta: P1 (b1) hedefe (3. satır) 2 hamlede varır.
    const cfg = GameConfig(
      boardSize: 3,
      armoryPoints: 0,
      startP1: Square(1, 0),
      startP2: Square(1, 2),
    );
    final controller = GameController(config: cfg, timed: false);
    final m = BoardMetrics(boardSize: 3, side: 300);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(
                    timed: false,
                    debugController: controller,
                  ),
                ),
              ),
              child: const Text('BAŞLAT'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('BAŞLAT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await settleScene(tester);

    // Oyunu bitir: P1 b1→b2, P2 b3→a3, P1 b2→b3 (3. satır = P1 kazanır).
    controller.tapBoard(m.cellCenter(const Square(1, 1)), m);
    controller.tapBoard(m.cellCenter(const Square(0, 2)), m);
    controller.tapBoard(m.cellCenter(const Square(1, 2)), m);
    expect(controller.isOver, isTrue);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Ana menü'), findsOneWidget);
    expect(find.text('Yeniden başlat'), findsOneWidget);

    await tester.tap(find.text('Ana menü'));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    // Oyun ekranı kapandı, başlatıcı geri geldi.
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('BAŞLAT'), findsOneWidget);

    controller.dispose();
  });
}
