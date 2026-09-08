import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';
import 'package:hatti_mudafaa/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpToMenu(WidgetTester tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      if (find.text('YEREL OYNA').evaluate().isNotEmpty) break;
    }
  }

  testWidgets('açılışta yükleme görünümü, hazır olunca ana menü', (tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());

    // İlk kare: ortak yükleme görünümü.
    expect(find.text('Yükleniyor'), findsOneWidget);

    await pumpToMenu(tester);

    expect(find.text('Yükleniyor'), findsNothing);
    expect(find.text('HATTI'), findsOneWidget);
    expect(find.text('MÜDAFAA'), findsOneWidget);
    expect(find.text('YEREL OYNA'), findsOneWidget);
    expect(find.text('Süreli mod'), findsOneWidget);
  });

  testWidgets('"?" düğmesi Nasıl Oynanır ekranını açar', (tester) async {
    await pumpToMenu(tester);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('NASIL OYNANIR'), findsOneWidget);
    expect(find.text('AMAÇ'), findsOneWidget);
    expect(find.text('ENGELLER'), findsOneWidget);
  });

  testWidgets('menüde "Yapay Zekaya Karşı" bölümü + üç zorluk düğmesi', (
    tester,
  ) async {
    await pumpToMenu(tester);

    expect(find.text('YAPAY ZEKAYA KARŞI'), findsOneWidget);
    expect(find.text('Kolay'), findsOneWidget);
    expect(find.text('Orta'), findsOneWidget);
    expect(find.text('Zor'), findsOneWidget);

    // "Zor"a dokununca yapay zeka oyun ekranı açılır (süresiz, sabit tahta).
    await tester.tap(find.text('Zor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.aiDifficulty, isNotNull);
    expect(screen.timed, isFalse);
    expect(screen.hotSeat, isFalse);

    // Flame sahnesi + yükleme animasyonu kapanana kadar pompala (bekleyen
    // zamanlayıcı kalmasın).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Cephe hazırlanıyor').evaluate().isEmpty) break;
    }
  });
}
