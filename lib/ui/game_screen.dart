import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game/board_component.dart';
import '../game/game_controller.dart';

/// Yerel (hot-seat) oyun ekranı: Flame tahtası + üstte durum, altta mod çubuğu.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final HattiBoardGame game;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    controller = GameController();
    game = HattiBoardGame(controller);
    controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChange);
    controller.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (controller.isOver && !_dialogOpen) {
      _dialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }
  }

  Future<void> _showWinDialog() async {
    final winner = controller.state.winner!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${_playerName(winner)} kazandı'),
        content: const Text('Yeni bir oyun başlatmak ister misin?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dialogOpen = false;
              controller.restart();
            },
            child: const Text('Yeniden başlat'),
          ),
        ],
      ),
    );
  }

  static String _playerName(Player p) => p == Player.p1 ? 'Mavi' : 'Kırmızı';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yerel oyun')),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => _StatusBar(controller: controller),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GameWidget(game: game),
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => _ControlBar(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final turnColor =
        state.turn == Player.p1 ? const Color(0xFF3E6E9E) : const Color(0xFFA2433B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 14, color: turnColor),
          const SizedBox(width: 8),
          Text(
            state.isOver
                ? 'Oyun bitti'
                : '${_GameScreenState._playerName(state.turn)} oynuyor',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.bolt, size: 18),
          const SizedBox(width: 4),
          Text('${controller.currentArmory}'),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Geri al',
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final inBarrierMode = controller.mode != InteractionMode.move;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Hareket',
                  icon: Icons.directions_walk,
                  selected: controller.mode == InteractionMode.move,
                  enabled: !controller.isOver,
                  onTap: () => controller.setMode(InteractionMode.move),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Mayın · 1',
                  icon: Icons.brightness_1,
                  selected: controller.mode == InteractionMode.mine,
                  enabled:
                      !controller.isOver && controller.canAfford(BarrierType.mine),
                  onTap: () => controller.setMode(InteractionMode.mine),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Tel · 2',
                  icon: Icons.dehaze,
                  selected: controller.mode == InteractionMode.wire,
                  enabled:
                      !controller.isOver && controller.canAfford(BarrierType.wire),
                  onTap: () => controller.setMode(InteractionMode.wire),
                ),
              ),
            ],
          ),
          if (inBarrierMode) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.preview == null
                        ? null
                        : controller.rotatePreview,
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('Döndür'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.canConfirmPreview
                        ? controller.confirmPreview
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'İptal',
                  onPressed: controller.preview == null
                      ? null
                      : controller.cancelPreview,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
