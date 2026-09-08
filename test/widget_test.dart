import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
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

  Future<void> drainScene(WidgetTester tester) async {
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Cephe hazırlanıyor').evaluate().isEmpty) break;
    }
  }

  testWidgets('menüde "Yapay Zekaya Karşı" + "Geniş Arazi" bölümleri', (
    tester,
  ) async {
    await pumpToMenu(tester);

    expect(find.text('YAPAY ZEKAYA KARŞI'), findsOneWidget);
    expect(find.text('GENİŞ ARAZİ'), findsOneWidget);
    expect(find.text('İKİ KİŞİLİK'), findsOneWidget);
    // Kolay/Orta/Zor her iki bölümde de var
    expect(find.text('Kolay'), findsNWidgets(2));
    expect(find.text('Orta'), findsNWidgets(2));
    expect(find.text('Zor'), findsNWidgets(2));

    // Üstteki "Zor" → normal 7×7 yapay zeka oyunu (süresiz, sabit tahta).
    await tester.tap(find.text('Zor').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.aiDifficulty, isNotNull);
    expect(screen.timed, isFalse);
    expect(screen.hotSeat, isFalse);
    expect(screen.config.boardSize, 7);
    expect(screen.snow, isFalse);

    await drainScene(tester);
  });

  testWidgets('Geniş Arazi "Zor" → 9×9 karlı yapay zeka oyunu', (tester) async {
    await pumpToMenu(tester);

    final wideZor = find.text('Zor').last;
    await tester.ensureVisible(wideZor);
    await tester.pump();
    await tester.tap(wideZor);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.config, GameConfig.wideTerrain);
    expect(screen.config.boardSize, 9);
    expect(screen.snow, isTrue);
    expect(screen.aiDifficulty, isNotNull);

    await drainScene(tester);
  });

  testWidgets('Geniş Arazi "İki Kişilik" → 9×9 hot-seat', (tester) async {
    await pumpToMenu(tester);

    final btn = find.text('İKİ KİŞİLİK');
    await tester.ensureVisible(btn);
    await tester.pump();
    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.config, GameConfig.wideTerrain);
    expect(screen.snow, isTrue);
    expect(screen.hotSeat, isTrue);
    expect(screen.aiDifficulty, isNull);

    await drainScene(tester);
  });
}
