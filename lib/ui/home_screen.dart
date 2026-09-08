import 'package:flutter/material.dart';
import 'package:game_ai/game_ai.dart';

import '../settings.dart';
import 'app_theme.dart';
import 'ash_fall.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'theme_backdrop.dart';

/// Ana menü. Sade tutulur; görsel derinlik [ThemeBackdrop] ile verilir.
/// Yapay zeka ve online sonraki fazlarda.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ThemeBackdrop.base,
      showDragHandle: true,
      builder: (context) => const _SettingsSheet(),
    );
  }

  void _openHowToPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const HowToPlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ThemeBackdrop(),
          // Sahnenin üstüne düşen kül / kor — oyun içindeki efektin menü
          // karşılığı. "Partiküller" kapalıyken hiç kurulmaz (Ticker da yok).
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.instance.particles,
            builder: (context, on, _) =>
                on ? const AshFall() : const SizedBox.shrink(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      const _MenuEntrance(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TitleBlock(),
                            SizedBox(height: 44),
                            _PlayButton(),
                            SizedBox(height: 14),
                            _TimedToggle(),
                            SizedBox(height: 30),
                            _AiSection(),
                          ],
                        ),
                      ),
                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: 'Nasıl oynanır',
                onPressed: () => _openHowToPlay(context),
                icon: const Icon(Icons.help_outline),
                color: AppPalette.text,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Ayarlar',
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_outlined),
                color: AppPalette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ana eylem — "saha tabelası": köşeli, amber, alt kenarı kalın (basılı his).
class _PlayButton extends StatelessWidget {
  const _PlayButton();

  void _startLocalGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GameScreen(timed: AppSettings.instance.timed.value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.amber,
      child: InkWell(
        onTap: () => _startLocalGame(context),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0x33FFFFFF)),
              bottom: BorderSide(color: AppPalette.amberDim, width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(46, 15, 46, 13),
          child: const Text(
            'YEREL OYNA',
            style: TextStyle(
              color: Color(0xFF201404),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

/// "YAPAY ZEKAYA KARŞI" bölümü — üç zorluk düğmesi, her birinin altında
/// seviye rütbesi (1/2/3 şerit). Süre yoktur; tahta yerel oyuncuya sabit bakar.
class _AiSection extends StatelessWidget {
  const _AiSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionRule(label: 'YAPAY ZEKAYA KARŞI'),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AiButton(
                difficulty: AiDifficulty.easy,
                label: 'Kolay',
                level: 1,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AiButton(
                difficulty: AiDifficulty.medium,
                label: 'Orta',
                level: 2,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AiButton(
                difficulty: AiDifficulty.hard,
                label: 'Zor',
                level: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ortada başlık, iki yanında ince çizgi.
class _SectionRule extends StatelessWidget {
  const _SectionRule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppPalette.line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppPalette.amberDim,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppPalette.line, height: 1)),
      ],
    );
  }
}

/// Tek zorluk düğmesi — köşeli koyu levha; üstte seviye rütbesi, altta ad.
class _AiButton extends StatelessWidget {
  const _AiButton({
    required this.difficulty,
    required this.label,
    required this.level,
  });

  final AiDifficulty difficulty;
  final String label;

  /// 1 (Kolay) · 2 (Orta) · 3 (Zor) — rütbe şeridi sayısı.
  final int level;

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen(
          hotSeat: false,
          timed: false,
          aiDifficulty: difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surfaceHi,
      child: InkWell(
        onTap: () => _start(context),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppPalette.line)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RankInsignia(level: level),
              const SizedBox(height: 9),
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zorluk göstergesi: üst üste üç "V" rütbe şeridi; [level] tanesi amber,
/// kalanı sönük. Askeri rütbe işaretine göz kırpar.
class _RankInsignia extends StatelessWidget {
  const _RankInsignia({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(30, 24),
        painter: _RankPainter(level),
      );
}

class _RankPainter extends CustomPainter {
  _RankPainter(this.level);

  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 3;
    const chevron = 6.0; // her şeridin yüksekliği
    const gap = 3.0;
    final w = size.width;

    for (var i = 0; i < count; i++) {
      final filled = i < level;
      final yBottom = size.height - i * (chevron + gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = filled ? 2.8 : 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = filled
            ? AppPalette.amber
            : AppPalette.line.withValues(alpha: 0.25);
      final path = Path()
        ..moveTo(w * 0.14, yBottom)
        ..lineTo(w * 0.5, yBottom - chevron)
        ..lineTo(w * 0.86, yBottom);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RankPainter old) => old.level != level;
}

/// Menü açılışında başlık + butonları bir kez yumuşakça belirtir (opaklık +
/// hafif yükseliş). Tek atış — [TweenAnimationBuilder] ilk kuruluşta çalışır.
class _MenuEntrance extends StatelessWidget {
  const _MenuEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 46,
      height: 1.05,
      fontWeight: FontWeight.w800,
      letterSpacing: 10,
      color: AppPalette.title,
    );
    return Column(
      children: [
        const Text('HATTI', style: style, textAlign: TextAlign.center),
        const Text('MÜDAFAA', style: style, textAlign: TextAlign.center),
        const SizedBox(height: 22),
        const SizedBox(width: 210, height: 22, child: _StandoffMark()),
      ],
    );
  }
}

/// Küçük tematik işaret: solda mavi, sağda kırmızı asker; aralarında amber
/// "cephe hattı". Oyunu tek bakışta anlatır.
class _StandoffMark extends StatelessWidget {
  const _StandoffMark();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _StandoffPainter());
}

class _StandoffPainter extends CustomPainter {
  const _StandoffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    const blue = Color(0xFF3E6E9E);
    const red = Color(0xFFA2433B);
    const amber = Color(0xFFE0A72E);

    final line = Paint()
      ..color = amber.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(24, midY), Offset(size.width - 24, midY), line);

    final tick = Paint()
      ..color = amber.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (var i = 1; i <= 5; i++) {
      final x = 24 + (size.width - 48) * i / 6;
      canvas.drawLine(Offset(x, midY - 4), Offset(x, midY + 4), tick);
    }

    canvas.drawCircle(Offset(8, midY), 6, Paint()..color = blue);
    canvas.drawCircle(
      Offset(size.width - 8, midY),
      6,
      Paint()..color = red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimedToggle extends StatelessWidget {
  const _TimedToggle();

  @override
  Widget build(BuildContext context) {
    final timed = AppSettings.instance.timed;
    return ValueListenableBuilder<bool>(
      valueListenable: timed,
      builder: (context, value, _) => Material(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => timed.value = !value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppPalette.line),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppPalette.text,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Süreli mod',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: value,
                  onChanged: (v) => timed.value = v,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Alttan açılan ayar paneli. Ses / Müzik / Partiküller anahtarları; ses ve
/// müzik hattı sonraki fazda bağlanacak (şimdilik yalnızca tercih saklanır).
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'AYARLAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppPalette.text,
                ),
              ),
            ),
            _SettingRow(
              icon: Icons.graphic_eq,
              label: 'Ses',
              subtitle: 'Efekt sesleri · yakında',
              notifier: AppSettings.instance.sound,
            ),
            _SettingRow(
              icon: Icons.music_note_outlined,
              label: 'Müzik',
              subtitle: 'Arka plan müziği · yakında',
              notifier: AppSettings.instance.music,
            ),
            _SettingRow(
              icon: Icons.blur_on,
              label: 'Partiküller',
              subtitle: 'Ateş, duman ve kül efektleri',
              notifier: AppSettings.instance.particles,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.notifier,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final ValueNotifier<bool> notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) => SwitchListTile(
        value: value,
        onChanged: (v) => notifier.value = v,
        secondary: Icon(icon, color: AppPalette.text),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
