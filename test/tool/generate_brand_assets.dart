@Tags(<String>['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/ui/brand_mark.dart';

/// Marka PNG'lerini `BrandMark`'tan üretir. **Gerçek test değil** — elle
/// çalıştırılır:
///
/// ```
/// flutter test test/tool/generate_brand_assets.dart
/// dart run flutter_launcher_icons
/// dart run flutter_native_splash:create
/// ```
///
/// CI bunu atlar: `flutter test --exclude-tags tool`.
void main() {
  testWidgets('marka varlıklarını üret', (tester) async {
    // Tam ikon — koyu zemin dahil (iOS + web + yedek).
    await _render(
      tester,
      const BrandMark(inset: 0.12),
      1024,
      'assets/brand/app_icon.png',
    );
    // Adaptif ikon ön planı (Android) — neredeyse tam kanvas; güvenli alan
    // payını mipmap-anydpi XML'i (inset %16) ekler.
    await _render(
      tester,
      const BrandMark(background: null, inset: 0.04),
      1024,
      'assets/brand/emblem_fg.png',
    );
    // Native açılış görseli — küçük, ortalanmış amblem (native_splash tuvali
    // ekrana yayar; bol pay bırakılır).
    await _render(
      tester,
      const BrandMark(background: null, inset: 0.30),
      1024,
      'assets/brand/splash.png',
    );

    // Web ikonları + favicon (flutter_launcher_icons web üretimi güvenilmez —
    // aynı kaynaktan elle basılır). Opak; maskable'da güvenli alan payı.
    await _render(tester, const BrandMark(inset: 0.12), 64, 'web/favicon.png');
    await _render(tester, const BrandMark(inset: 0.12), 192,
        'web/icons/Icon-192.png');
    await _render(tester, const BrandMark(inset: 0.12), 512,
        'web/icons/Icon-512.png');
    await _render(tester, const BrandMark(inset: 0.26), 192,
        'web/icons/Icon-maskable-192.png');
    await _render(tester, const BrandMark(inset: 0.26), 512,
        'web/icons/Icon-maskable-512.png');
  });
}

Future<void> _render(
  WidgetTester tester,
  Widget mark,
  double side,
  String path,
) async {
  final size = Size.square(side);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox.fromSize(size: size, child: mark),
    ),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('yazıldı: $path (${bytes.length} bayt)');
}
