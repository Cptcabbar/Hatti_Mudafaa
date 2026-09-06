import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/game/board_projection.dart';

void main() {
  Matcher closeOffset(Offset o, {double eps = 0.01}) => predicate<Offset>(
        (p) => (p.dx - o.dx).abs() < eps && (p.dy - o.dy).abs() < eps,
        'yaklaşık $o',
      );

  test('tilt=0 birebir düz izdüşüm', () {
    final p = BoardProjection(side: 700, tilt: 0);
    expect(p.isFlat, isTrue);
    expect(p.project(const Offset(0, 0)), closeOffset(const Offset(0, 0)));
    expect(p.project(const Offset(700, 700)), closeOffset(const Offset(700, 700)));
    expect(p.project(const Offset(350, 350)), closeOffset(const Offset(350, 350)));
  });

  test('project/unproject gidiş-dönüş birebir tersinir', () {
    for (final tilt in const [-1.0, -0.6, -0.15, 0.0, 0.2, 0.55, 1.0]) {
      final p = BoardProjection(side: 700, tilt: tilt);
      for (final flat in const [
        Offset(10, 10),
        Offset(690, 20),
        Offset(350, 350),
        Offset(120, 600),
        Offset(680, 690),
      ]) {
        final round = p.unproject(p.project(flat));
        expect(round, closeOffset(flat, eps: 0.05),
            reason: 'tilt=$tilt flat=$flat');
      }
    }
  });

  test('pozitif tilt: alt kenar yakın (daha geniş), üst kenar uzak (daha dar)',
      () {
    final p = BoardProjection(side: 700, tilt: 1);
    final topSpan =
        (p.project(const Offset(700, 0)) - p.project(const Offset(0, 0))).distance;
    final botSpan = (p.project(const Offset(700, 700)) -
            p.project(const Offset(0, 700)))
        .distance;
    expect(botSpan, greaterThan(topSpan));
  });

  test('negatif tilt: üst kenar yakın', () {
    final p = BoardProjection(side: 700, tilt: -1);
    final topSpan =
        (p.project(const Offset(700, 0)) - p.project(const Offset(0, 0))).distance;
    final botSpan = (p.project(const Offset(700, 700)) -
            p.project(const Offset(0, 700)))
        .distance;
    expect(topSpan, greaterThan(botSpan));
  });

  test('eğik izdüşümde uzak taşlar küçülür (scaleAt)', () {
    final p = BoardProjection(side: 700, tilt: 1);
    final near = p.scaleAt(const Offset(350, 650)); // alt = yakın
    final far = p.scaleAt(const Offset(350, 50)); // üst = uzak
    expect(near, greaterThan(far));
    expect(far, greaterThan(0));
  });
}
