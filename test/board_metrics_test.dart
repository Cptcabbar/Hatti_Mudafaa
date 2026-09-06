import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:hatti_mudafaa/game/board_metrics.dart';

void main() {
  final m = BoardMetrics(boardSize: 7, side: 700); // hücre = 100

  test('cellRect / cellCenter — satır 0 altta', () {
    expect(m.cellRect(Square.parse('a1')), const Rect.fromLTWH(0, 600, 100, 100));
    expect(m.cellCenter(Square.parse('a1')), const Offset(50, 650));
    expect(m.cellCenter(Square.parse('d7')), const Offset(350, 50));
  });

  test('squareAt — piksel → kare', () {
    expect(m.squareAt(const Offset(50, 650)), Square.parse('a1'));
    expect(m.squareAt(const Offset(350, 50)), Square.parse('d7'));
    expect(m.squareAt(const Offset(-1, 10)), isNull);
    expect(m.squareAt(const Offset(10, 701)), isNull);
  });

  group('barrierLine — çizim geometrisi', () {
    test('yatay mayın Mc3h', () {
      expect(
        m.barrierLine(Barrier.parse('Mc3h')),
        (const Offset(200, 400), const Offset(300, 400)),
      );
    });

    test('yatay tel Wc3h iki kare boyu', () {
      expect(
        m.barrierLine(Barrier.parse('Wc3h')),
        (const Offset(200, 400), const Offset(400, 400)),
      );
    });

    test('dikey mayın Mc3v', () {
      expect(
        m.barrierLine(Barrier.parse('Mc3v')),
        (const Offset(300, 500), const Offset(300, 400)),
      );
    });

    test('dikey tel Wc3v iki kare boyu', () {
      expect(
        m.barrierLine(Barrier.parse('Wc3v')),
        (const Offset(300, 500), const Offset(300, 300)),
      );
    });
  });

  test('nearestBarrierSlot — ızgara çizgisine snap eder', () {
    // y=400 tam yatay çizgi üzerinde, x=250 → yatay engel, kuzey kenarı
    final slot = m.nearestBarrierSlot(const Offset(250, 400), BarrierType.mine);
    expect(slot.orientation, BarrierOrientation.horizontal);
    // x=300 tam dikey çizgi, y=250 → dikey engel
    final slot2 = m.nearestBarrierSlot(const Offset(300, 250), BarrierType.wire);
    expect(slot2.orientation, BarrierOrientation.vertical);
  });
}
