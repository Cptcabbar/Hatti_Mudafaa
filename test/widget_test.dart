import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('açılışta yükleme görünümü, hazır olunca ana menü', (tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());

    // İlk kare: ortak yükleme görünümü.
    expect(find.text('Yükleniyor'), findsOneWidget);

    // Açılış hazırlığı (ayar yükleme dahil) birkaç microtask sürebilir.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      if (find.text('YEREL OYNA').evaluate().isNotEmpty) break;
    }

    expect(find.text('Yükleniyor'), findsNothing);
    expect(find.text('HATTI'), findsOneWidget);
    expect(find.text('MÜDAFAA'), findsOneWidget);
    expect(find.text('YEREL OYNA'), findsOneWidget);
    expect(find.text('Süreli mod'), findsOneWidget);
  });
}
