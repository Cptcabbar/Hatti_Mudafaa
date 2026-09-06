import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const KapaliYolApp());
}

/// Uygulama kökü. Faz 0 iskeleti — menü, oyun ekranı ve reklam yuvası
/// sonraki fazlarda eklenecek (bkz. ROADMAP.md).
class KapaliYolApp extends StatelessWidget {
  const KapaliYolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kapalı Yol',
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
