import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game/board_component.dart';
import '../game/game_controller.dart';
import 'loading_view.dart';

/// Yerel (hot-seat) oyun ekranı.
///
/// Telefon masaya yatık konur; iki oyuncu karşılıklı oturur. Her oyuncunun
/// kendi paneli kendi tarafındadır (üstteki 180° dönük). Sıra sende değilken
/// panelin katlanır. Süreli modda her tur 30 sn — sayaç sağ kenarda.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.timed = true, this.hotSeat = true});

  final bool timed;

  /// `true`: iki kişi aynı cihazda — tahta her sıra dönen oyuncuya bakar.
  /// `false` (Faz 2, yapay zeka): tahta sabit, yerel oyuncuya bakar.
  final bool hotSeat;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final HattiBoardGame game;
  bool _dialogOpen = false;
  bool _sceneReady = false;

  @override
  void initState() {
    super.initState();
    controller = GameController(timed: widget.timed);
    game = HattiBoardGame(controller, hotSeat: widget.hotSeat);
    controller.addListener(_onControllerChange);
    // Flame sahnesi yüklenene + shader ısınması (ilk kareler eğimi tüm aralıkta
    // gezdirir) bitene kadar ortak yükleme görünümü tam ekran örtsün — böylece
    // ilk sıra değişimi dönüşünde shader derleme takılması görünmez.
    game.loaded.then((_) async {
      try {
        await game.board.primeReady.timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (mounted) setState(() => _sceneReady = true);
    });
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
    if (!mounted) return;
    final winner = controller.state.winner!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${playerName(winner)} kazandı'),
        content: const Text('Yeni bir oyun başlatmak ister misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          FilledButton(
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

  static String playerName(Player p) => p == Player.p1 ? 'Mavi' : 'Kırmızı';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: _buildGame()),
          if (!_sceneReady)
            const Positioned.fill(
              child: LoadingView(message: 'Cephe hazırlanıyor'),
            ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            _PlayerPanel(
              controller: controller,
              player: Player.p2,
              rotated: true,
            ),
            Expanded(
              child: Stack(
                children: [
                  // Flame tuvali kendini kırpmaz; çevre katmanları (gökyüzü,
                  // ufuk parıltısı, silüet, vinyet) uzak kenarın ötesine taşar.
                  // ClipRect olmadan bu koyu katmanlar panellerin üstüne sarkıp
                  // butonları karartıyordu.
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRect(child: GameWidget(game: game)),
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Çıkış',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  if (widget.timed)
                    Positioned(
                      right: 4,
                      top: 8,
                      bottom: 8,
                      width: 30,
                      child: _TurnTimer(controller: controller),
                    ),
                ],
              ),
            ),
            _PlayerPanel(
              controller: controller,
              player: Player.p1,
              rotated: false,
            ),
          ],
        );
      },
    );
  }
}

/// Bir oyuncunun kontrol paneli. Sırası ondaysa açık, değilse katlı.
class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.controller,
    required this.player,
    required this.rotated,
  });

  final GameController controller;
  final Player player;
  final bool rotated;

  Color get _color =>
      player == Player.p1 ? const Color(0xFF3E6E9E) : const Color(0xFFA2433B);

  bool get _active => controller.turn == player && !controller.isOver;

  @override
  Widget build(BuildContext context) {
    // Her iki gövde de ağaçta kalır (yalnızca görünürlük değişir) — sıra
    // değişince panel alt ağacı sıfırdan kurulup düzenlenmez; ilk dönüşteki
    // takılmayı azaltır.
    final body = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Offstage(offstage: _active, child: _foldedBody(context)),
          Offstage(offstage: !_active, child: _activeBody(context)),
        ],
      ),
    );
    return Material(
      color: _color.withValues(alpha: _active ? 0.14 : 0.06),
      child: rotated ? RotatedBox(quarterTurns: 2, child: body) : body,
    );
  }

  Widget _foldedBody(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.isOver ? Icons.flag : Icons.lock_outline,
            size: 16,
            color: _color,
          ),
          const SizedBox(width: 8),
          Text(
            controller.isOver
                ? 'Oyun bitti'
                : '${_GameScreenState.playerName(player)} · sıra rakipte',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.bolt, size: 16),
          Text(' ${controller.armoryOf(player)}'),
        ],
      ),
    );
  }

  Widget _activeBody(BuildContext context) {
    final inBarrierMode = controller.mode != InteractionMode.move;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 14, color: _color),
              const SizedBox(width: 8),
              Text(
                '${_GameScreenState.playerName(player)} oynuyor',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.bolt, size: 18),
              const SizedBox(width: 2),
              Text('${controller.armoryOf(player)}'),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Geri al',
                visualDensity: VisualDensity.compact,
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Hareket',
                  icon: Icons.directions_walk,
                  selected: controller.mode == InteractionMode.move,
                  enabled: true,
                  onTap: () => controller.setMode(InteractionMode.move),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Mayın · 1',
                  icon: Icons.brightness_1,
                  selected: controller.mode == InteractionMode.mine,
                  enabled: controller.canAfford(BarrierType.mine),
                  onTap: () => controller.setMode(InteractionMode.mine),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Tel · 2',
                  icon: Icons.dehaze,
                  selected: controller.mode == InteractionMode.wire,
                  enabled: controller.canAfford(BarrierType.wire),
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

/// Sağ kenarda dikey tur sayacı.
///
/// Dolu çubuk **sıradaki oyuncuya göre** azalır: P1 (düz) turunda ekranın
/// altına doğru, P2 (180° dönük) turunda ekranın üstüne doğru — böylece her
/// oyuncu için "aşağı akıyor" gibi görünür. Saniye sayısı iki uçta yazılır;
/// aktif oyuncuya bakan uç vurgulu.
class _TurnTimer extends StatelessWidget {
  const _TurnTimer({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final fraction = controller.turnFraction;
    final seconds = controller.secondsLeft.ceil().clamp(0, 999);
    final activeIsP2 = controller.turn == Player.p2 && !controller.isOver;

    final Color barColor;
    if (fraction > 0.5) {
      barColor = const Color(0xFF4CAF50);
    } else if (fraction > 0.2) {
      barColor = const Color(0xFFE0A72E);
    } else {
      barColor = const Color(0xFFE5484D);
    }

    Widget label({required int quarterTurns, required bool active}) => RotatedBox(
          quarterTurns: quarterTurns,
          child: Text(
            '$seconds',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: active ? 14 : 12,
              color: Colors.white.withValues(alpha: active ? 1 : 0.4),
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: const Color(0xFF14110D).withValues(alpha: 0.85),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              // P2 turunda çubuk yukarıdan (P2'nin "aşağısı") azalır.
              alignment:
                  activeIsP2 ? Alignment.topCenter : Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: controller.isOver ? 0 : fraction,
                widthFactor: 1,
                child: ColoredBox(color: barColor.withValues(alpha: 0.85)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // üstteki uç P2'ye bakar (ters)
                  label(quarterTurns: 2, active: activeIsP2),
                  // alttaki uç P1'e bakar (düz)
                  label(quarterTurns: 0, active: !activeIsP2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
