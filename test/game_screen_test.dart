import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/ui/game_screen.dart';

void main() {
  testWidgets('oyun ekranı açılır: durum çubuğu + mod düğmeleri', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(timed: false)));
    await tester.pump();

    expect(find.text('Mavi oynuyor'), findsOneWidget);
    expect(find.text('Hareket'), findsOneWidget);
    expect(find.text('Mayın · 1'), findsOneWidget);
    expect(find.text('Tel · 2'), findsOneWidget);
    // engel modu seçilmeden Döndür/Onayla görünmez
    expect(find.text('Onayla'), findsNothing);
  });

  testWidgets('Mayın moduna geçince onay çubuğu belirir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(timed: false)));
    await tester.pump();

    await tester.tap(find.text('Mayın · 1'));
    await tester.pump();

    expect(find.text('Döndür'), findsOneWidget);
    expect(find.text('Onayla'), findsOneWidget);
  });
}
