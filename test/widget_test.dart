import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';

void main() {
  testWidgets('uygulama açılır ve ana menüyü gösterir', (tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());
    expect(find.text('HATTI'), findsOneWidget);
    expect(find.text('MÜDAFAA'), findsOneWidget);
    expect(find.text('YEREL OYNA'), findsOneWidget);
    expect(find.text('Süreli mod'), findsOneWidget);
  });
}
