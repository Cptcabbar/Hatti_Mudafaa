import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/main.dart';

void main() {
  testWidgets('uygulama açılır ve başlığı gösterir', (tester) async {
    await tester.pumpWidget(const HattiMudafaaApp());
    expect(find.text('HATTI MÜDAFAA'), findsOneWidget);
    expect(find.textContaining('7×7'), findsOneWidget);
  });
}
