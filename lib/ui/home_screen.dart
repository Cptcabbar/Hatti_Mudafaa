import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// Geçici ana ekran (Faz 0). Faz 1'de gerçek menü + yerel oyun gelecek.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const config = GameConfig.v1;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HATTI MÜDAFAA',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'sıra tabanlı strateji · Faz 0 iskeleti',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Tahta: ${config.boardSize}×${config.boardSize}'),
            Text('Cephanelik: ${config.armoryPoints} puan'),
          ],
        ),
      ),
    );
  }
}
