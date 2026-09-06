import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'game_screen.dart';

/// Ana menü (Faz 1). Yapay zeka ve online sonraki fazlarda.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const config = GameConfig.v1;
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                'sıra tabanlı strateji',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const GameScreen(),
                  ),
                ),
                icon: const Icon(Icons.people),
                label: const Text('Yerel oyna (2 kişi)'),
              ),
              const SizedBox(height: 24),
              Text(
                'Tahta ${config.boardSize}×${config.boardSize} · '
                'cephanelik ${config.armoryPoints} puan',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
