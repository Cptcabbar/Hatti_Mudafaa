import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_ai/game_ai.dart';
import 'package:game_core/game_core.dart';

import '../game/board_component.dart';
import '../game/game_controller.dart';
import 'app_theme.dart';
import 'game_marks.dart';
import 'loading_view.dart';

/// Yerel (hot-seat) oyun ekranı.
///
/// Telefon masaya yatık konur; iki oyuncu karşılıklı oturur. Her oyuncunun
/// kendi paneli kendi tarafındadır (üstteki 180° dönük). Sıra sende değilken
/// panelin katlanır. Süreli modda her tur 30 sn — sayaç sağ kenarda.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.timed = true,
    this.hotSeat = true,
    this.aiDifficulty,
  });

  final bool timed;

  /// `true`: iki kişi aynı cihazda — tahta her sıra dönen oyuncuya bakar.
  /// `false` (yapay zeka): tahta sabit, yerel oyuncuya bakar.
  final bool hotSeat;

  /// Doluysa oyun yapay zekaya karşı (Kırmızı'yı AI oynar); süre yoktur.
  final AiDifficulty? aiDifficulty;

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
    controller = GameController(
      timed: widget.timed,
      aiDifficulty: widget.aiDifficulty,
    );
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
    final String title;
    if (controller.vsAi) {
      title = winner == controller.aiPlayer
          ? 'Yapay zeka kazandı'
          : 'Kazandın!';
    } else {
      title = '${playerName(winner)} kazandı';
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
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
    // Yalnızca controller'a bağlı parçalar (paneller + sayaç) `AnimatedBuilder`
    // içinde yeniden kurulur. `GameWidget` + kenar düğmeleri sabit kalır —
    // her hamlede / sayaç tıkında ağır Flame widget ağacını yeniden kurmayız
    // (engel koyduktan sonraki onay karesindeki takılmayı azaltır).
    final gameArea = Expanded(
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
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => _TurnTimer(controller: controller),
              ),
            ),
        ],
      ),
    );

    Widget panel(Player p, {required bool rotated}) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) => _PlayerPanel(
            controller: controller,
            player: p,
            rotated: rotated,
          ),
        );

    return Column(
      children: [
        // Yapay zeka modunda kimse üst tarafta oturmaz — panel düz dursun.
        panel(Player.p2, rotated: widget.hotSeat),
        gameArea,
        panel(Player.p1, rotated: false),
      ],
    );
  }
}

/// Bir oyuncunun kontrol paneli — "cephe konsolu". Sırası ondaysa açık (mod
/// çipleri + eylem çubuğu), değilse katlı kilitli şerit. Tahtaya bakan
/// kenarında tarafın soluk boya bandı + perçin sırası.
class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.controller,
    required this.player,
    required this.rotated,
  });

  final GameController controller;
  final Player player;
  final bool rotated;

  /// Tarafın soluk boyası — asker miğferiyle aynı ton (`_Faction.p1/p2`).
  Color get _accent => player == Player.p1 ? AppPalette.p1 : AppPalette.p2;

  /// Bu panel yapay zekaya mı ait — öyleyse etkileşimli gövde hiç açılmaz.
  bool get _isAiPanel => controller.vsAi && controller.aiPlayer == player;

  bool get _active =>
      controller.turn == player && !controller.isOver && !_isAiPanel;

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

    // Column'un ilk çocuğu kenar şeridi; RotatedBox sonrası P2 için ekranın
    // alt kenarına (tahtaya bakan tarafa) düşer.
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _active
              ? const [Color(0xFF231C12), Color(0xFF16120C)]
              : const [Color(0xFF141009), Color(0xFF100C07)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrenchEdge(
            color: _accent,
            active: _active || (_isAiPanel && controller.aiThinking),
          ),
          body,
        ],
      ),
    );

    return Material(
      color: AppPalette.base,
      child: rotated ? RotatedBox(quarterTurns: 2, child: content) : content,
    );
  }

  Widget _foldedBody(BuildContext context) {
    if (_isAiPanel && controller.aiThinking) return const _ThinkingStrip();
    final over = controller.isOver;
    final IconData icon;
    final String label;
    if (over) {
      icon = Icons.flag_outlined;
      label = 'Oyun bitti';
    } else if (_isAiPanel) {
      icon = Icons.smart_toy_outlined;
      label = '${_GameScreenState.playerName(player)} · yapay zeka';
    } else {
      icon = Icons.lock_outline;
      label = '${_GameScreenState.playerName(player)} · sıra rakipte';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppPalette.text,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          const SupplyMark(size: 11, color: AppPalette.amberDim),
          Text(
            ' ${controller.armoryOf(player)}',
            style: const TextStyle(color: AppPalette.text),
          ),
        ],
      ),
    );
  }

  Widget _activeBody(BuildContext context) {
    final inBarrierMode = controller.mode != InteractionMode.move;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: _accent),
              const SizedBox(width: 8),
              Text(
                '${_GameScreenState.playerName(player)} oynuyor',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.title,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              _ArmoryTag(count: controller.armoryOf(player)),
              const SizedBox(width: 2),
              IconButton(
                tooltip: 'Geri al',
                visualDensity: VisualDensity.compact,
                color: AppPalette.text,
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Hareket',
                  mark: (color, size) =>
                      Icon(Icons.directions_walk, size: size, color: color),
                  selected: controller.mode == InteractionMode.move,
                  enabled: true,
                  onTap: () => controller.setMode(InteractionMode.move),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Mayın',
                  cost: 1,
                  mark: (color, size) => MineMark(size: size, color: color),
                  selected: controller.mode == InteractionMode.mine,
                  enabled: controller.canAfford(BarrierType.mine),
                  onTap: () => controller.setMode(InteractionMode.mine),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Tel',
                  cost: 2,
                  mark: (color, size) => WireMark(size: size, color: color),
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
                  child: _FieldButton(
                    icon: Icons.rotate_right,
                    label: 'Döndür',
                    onPressed: controller.preview == null
                        ? null
                        : controller.rotatePreview,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FieldButton(
                    icon: Icons.check,
                    label: 'Onayla',
                    primary: true,
                    onPressed: controller.canConfirmPreview
                        ? controller.confirmPreview
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                _FieldButton(
                  icon: Icons.close,
                  tooltip: 'İptal',
                  onPressed: controller.preview == null
                      ? null
                      : controller.cancelPreview,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Yapay zeka hamlesini düşünürken panelde görünen şerit — yükleme ekranıyla
/// aynı görsel dil (amber radar taraması). Tahtayı örtmez: insan oyuncu bu
/// 3-5 sn'lik pencerede kendi hamlesini planlayabilir.
class _ThinkingStrip extends StatelessWidget {
  const _ThinkingStrip();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RadarSpinner(size: 20),
          SizedBox(width: 12),
          Text(
            'YAPAY ZEKA DÜŞÜNÜYOR',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 2.5,
              color: AppPalette.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panelin tahtaya bakan kenarı: tarafın soluk boya bandı + ince metal
/// parıltısı + perçin sırası. Sıra sende değilken sönük.
class _TrenchEdge extends StatelessWidget {
  const _TrenchEdge({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 7,
        width: double.infinity,
        child: CustomPaint(painter: _TrenchEdgePainter(color, active)),
      );
}

class _TrenchEdgePainter extends CustomPainter {
  _TrenchEdgePainter(this.color, this.active);

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final a = active ? 1.0 : 0.4;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, 3),
        Paint()..color = color.withValues(alpha: 0.6 * a),
      )
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, 1),
        Paint()..color = const Color(0xFFF3ECDC).withValues(alpha: 0.10 * a),
      );
    final rivet = Paint()
      ..color = const Color(0xFF0E0B06).withValues(alpha: 0.65 * a);
    final n = (size.width / 32).floor().clamp(5, 16);
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(size.width * (i + 0.5) / n, 5), 1.4, rivet);
    }
  }

  @override
  bool shouldRepaint(covariant _TrenchEdgePainter old) =>
      old.color != color || old.active != active;
}

/// Kalan cephanelik puanı — küçük çerçeveli etiket ("cephane" logosu + sayı).
class _ArmoryTag extends StatelessWidget {
  const _ArmoryTag({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
        decoration: BoxDecoration(border: Border.all(color: AppPalette.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SupplyMark(size: 12),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
}

/// Etkileşim modu seçici — köşeli. Seçili: amber basılı levha (üst ışık +
/// kalın alt kenar). Pasif: koyu yüzey + ince çerçeve. Alınamıyorsa soluk.
/// Engel modlarında ikinci satırda maliyet: sayı + "cephane" logosu.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.mark,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.cost,
  });

  final String label;

  /// İkonu istenen renk + boyutta üretir (özel çizim ya da Material ikon).
  final Widget Function(Color color, double size) mark;
  final int? cost;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF201404) : AppPalette.text;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: selected ? AppPalette.amber : AppPalette.surfaceHi,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              border: selected
                  ? const Border(
                      top: BorderSide(color: Color(0x30FFFFFF)),
                      bottom: BorderSide(color: AppPalette.amberDim, width: 2.5),
                    )
                  : Border.all(color: AppPalette.line),
            ),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 19, child: Center(child: mark(fg, 19))),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                // Maliyet satırı — çipler eşit yükseklikte kalsın diye her zaman
                // ayrılır (Hareket'te boş).
                SizedBox(
                  height: 14,
                  child: cost == null
                      ? null
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$cost',
                              style: TextStyle(
                                color: fg,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 3),
                            SupplyMark(size: 9.5, color: fg),
                          ],
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

/// Köşeli eylem düğmesi. `primary`: amber basılı levha. Değilse: hayalet
/// (şeffaf + ince çerçeve). `label` verilmezse yalnız ikon (İptal gibi).
class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.primary = false,
  });

  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = primary ? const Color(0xFF201404) : AppPalette.text;
    final iconOnly = label == null;

    Widget button = Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: primary ? AppPalette.amber : Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: primary
                  ? const Border(
                      top: BorderSide(color: Color(0x30FFFFFF)),
                      bottom: BorderSide(color: AppPalette.amberDim, width: 2.5),
                    )
                  : Border.all(color: AppPalette.line),
            ),
            padding: EdgeInsets.symmetric(
              vertical: 9,
              horizontal: iconOnly ? 12 : 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: fg),
                if (!iconOnly) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
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
