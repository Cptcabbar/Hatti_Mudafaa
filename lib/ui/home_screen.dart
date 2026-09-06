import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'game_screen.dart';

/// Ana menü (Faz 1). Yapay zeka ve online sonraki fazlarda.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _timed = true;

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
                    builder: (context) => GameScreen(timed: _timed),
                  ),
                ),
                icon: const Icon(Icons.people),
                label: const Text('Yerel oyna (2 kişi)'),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SwitchListTile(
                  value: _timed,
                  onChanged: (v) => setState(() => _timed = v),
                  title: const Text('Süreli mod'),
                  subtitle: const Text('Her tur 30 saniye'),
                ),
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
