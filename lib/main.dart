import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';
import 'ui/app_theme.dart';
import 'ui/home_screen.dart';
import 'ui/loading_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HattiMudafaaApp());
}

/// Uygulama kökü. Faz 1 — yerel (hot-seat) oyun. Reklam yuvası ve online
/// sonraki fazlarda (bkz. ROADMAP.md).
class HattiMudafaaApp extends StatelessWidget {
  const HattiMudafaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hattı Müdafaa',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Bootstrap(),
    );
  }
}

/// Açılış hazırlığı. Şimdilik hızlı (yön kilidi); ileride font/atlas/ayar/ads
/// yüklemesi buraya `await` edilecek. Hazır olana kadar oyunun ortak yükleme
/// görünümü ([LoadingView]) gösterilir — uygulama ilk kareden itibaren tek bir
/// görsel dilde açılır.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<void> _ready = _prepare();

  Future<void> _prepare() async {
    // Yön kilidi UI'ı bekletmemeli; platform yanıtını beklemeden geçiyoruz.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    await AppSettings.instance.load();
    // İleride: await _loadFontsAndAtlas(); ...
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }
        return const LoadingView();
      },
    );
  }
}
