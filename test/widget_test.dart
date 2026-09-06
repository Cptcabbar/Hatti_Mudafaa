import 'package:flutter_test/flutter_test.dart';
import 'package:kapali_yol/main.dart';

void main() {
  testWidgets('uygulama açılır ve başlığı gösterir', (tester) async {
    await tester.pumpWidget(const KapaliYolApp());
    expect(find.text('KAPALI YOL'), findsOneWidget);
    expect(find.textContaining('7×7'), findsOneWidget);
  });
}
