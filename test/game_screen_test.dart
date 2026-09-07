import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
