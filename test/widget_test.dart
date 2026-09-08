import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';
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
}
