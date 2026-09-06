import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B5320), // asker yeşili — geçici
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
