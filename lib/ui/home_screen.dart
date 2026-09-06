import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'theme_backdrop.dart';

/// Ana menü. Sade tutulur; görsel derinlik [ThemeBackdrop] ile verilir.
/// Yapay zeka ve online sonraki fazlarda.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _timed = true;

  void _startLocalGame() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen(timed: _timed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ThemeBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      const _TitleBlock(),
                      const SizedBox(height: 56),
                      FilledButton(
                        onPressed: _startLocalGame,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: const Text('YEREL OYNA'),
                      ),
                      const SizedBox(height: 16),
                      _TimedToggle(
                        value: _timed,
                        onChanged: (v) => setState(() => _timed = v),
                      ),
                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      color: Color(0xFFEDE7D6),
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
  const _TimedToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Süreli mod',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
