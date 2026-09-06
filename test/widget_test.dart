import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';

void main() {
  testWidgets('açılışta yükleme görünümü, hazır olunca ana menü', (tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());

    // İlk kare: ortak yükleme görünümü.
    expect(find.text('Yükleniyor'), findsOneWidget);

    // Açılış hazırlığı bitince ana menü.
    await tester.pump();

    expect(find.text('Yükleniyor'), findsNothing);
    expect(find.text('HATTI'), findsOneWidget);
    expect(find.text('MÜDAFAA'), findsOneWidget);
    expect(find.text('YEREL OYNA'), findsOneWidget);
    expect(find.text('Süreli mod'), findsOneWidget);
  });
}
