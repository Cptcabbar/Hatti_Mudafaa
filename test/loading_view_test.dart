import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/ui/loading_view.dart';
import 'package:hatti_mudafaa/ui/theme_backdrop.dart';

void main() {
  testWidgets('varsayılan "Yükleniyor" yazısı + ortak arka plan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingView()));
    await tester.pump(const Duration(milliseconds: 100)); // radar birkaç kare

    expect(find.text('Yükleniyor'), findsOneWidget);
    expect(find.byType(ThemeBackdrop), findsOneWidget);
  });

  testWidgets('özel mesaj gösterilebilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoadingView(message: 'Sahne hazırlanıyor')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sahne hazırlanıyor'), findsOneWidget);
  });
}
