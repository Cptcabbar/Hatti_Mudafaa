import 'dart:typed_data';
import 'dart:ui';

/// Tahtayı üstten görünümden, sıradaki oyuncuya doğru hafifçe eğen izdüşüm.
///
/// [tilt] = 0 düz üstten bakış; **+1** alt kenarı yakına getirir (P1 tarafı,
/// düz panel), **-1** üst kenarı yakına getirir (P2 tarafı, 180° dönük panel).
/// Ara değerler [BoardComponent] tarafından sıra değişince yumuşakça
/// animasyonlanır — böylece masaya yatık iki oyuncu da kendi sırasında
/// tahtaya "hafif önden" bakar.
///
/// [project] düz tahta pikselini (0..[side]) ekran pikseline çevirir;
/// [unproject] tersidir (dokunma → kare). Altında projektif bir homografi
/// vardır; gidiş-dönüş birebir tersinirdir (bkz. `board_projection_test`).
class BoardProjection {
  BoardProjection({
    required this.side,
    required double tilt,
    this.farWidth = 0.86,
    this.heightScale = 0.85,
    this.lift = 0.0,
  }) : tilt = tilt.clamp(-1.0, 1.0) {
    _build();
  }

  /// Düz tahtanın kenar uzunluğu (piksel).
  final double side;

  /// -1..1 eğim miktarı.
  final double tilt;

  /// |tilt|=1'de uzak kenarın genişliği (yakın kenara oran).
  final double farWidth;

  /// |tilt|=1'de tahtanın dikey sıkışması.
  final double heightScale;

  /// |tilt|=1'de tahtayı uzak kenardan biraz iterek çerçeveleme payı.
  final double lift;

  // 3x3 satır-öncelikli homografiler: (x, y, 1) -> (X, Y, W); nokta = (X/W, Y/W).
  late final List<double> _m; // düz piksel -> ekran piksel
  late final List<double> _mInv; // ekran piksel -> düz piksel

  bool get isFlat => tilt.abs() < 1e-4;

  void _build() {
    final s = tilt;
    final a = s.abs();
    final fw = _lerp(1.0, farWidth, a);
    final halfH = _lerp(1.0, heightScale, a) * 0.5;
    final shift = (s.isNegative ? -1.0 : 1.0) * lift * a;
    const c = 0.5;
    final farHalf = 0.5 * fw;
    const nearHalf = 0.5;
    final topY = c - halfH + shift;
    final botY = c + halfH + shift;

    // [0,1] normalize kare köşeleri (0,0),(1,0),(1,1),(0,1) -> hedef dörtgen.
    final List<Offset> dst;
    if (s >= 0) {
      // yakın kenar = alt
      dst = [
        Offset(c - farHalf, topY),
        Offset(c + farHalf, topY),
        Offset(c + nearHalf, botY),
        Offset(c - nearHalf, botY),
      ];
    } else {
      // yakın kenar = üst
      dst = [
        Offset(c - nearHalf, topY),
        Offset(c + nearHalf, topY),
        Offset(c + farHalf, botY),
        Offset(c - farHalf, botY),
      ];
    }

    final h = _squareToQuad([for (final o in dst) Offset(o.dx * side, o.dy * side)]);
    // h, (u,v) girişini bekler; düz piksel (0..side) girişi için 1/side ölçekle.
    _m = [
      h[0] / side, h[1] / side, h[2],
      h[3] / side, h[4] / side, h[5],
      h[6] / side, h[7] / side, h[8],
    ];
    _mInv = _invert3(_m);
  }

  /// Düz tahta pikseli → ekran pikseli.
  Offset project(Offset flat) => _apply(_m, flat.dx, flat.dy);

  /// Ekran pikseli → düz tahta pikseli.
  Offset unproject(Offset screen) => _apply(_mInv, screen.dx, screen.dy);

  /// [flat] çevresinde yerel yatay ölçek — "billboard" taş/işaret boyutu için
  /// (uzak ≈ [farWidth], yakın ≈ 1).
  double scaleAt(Offset flat) {
    const e = 4.0;
    return (project(flat + const Offset(e, 0)) - project(flat)).distance / e;
  }

  /// [flat] çevresinde yerel dikey ölçek — zemine düşen gölgeyi yassıltmak için.
  double verticalScaleAt(Offset flat) {
    const e = 4.0;
    return (project(flat + const Offset(0, e)) - project(flat)).distance / e;
  }

  /// `Canvas.transform` için 4x4 (sütun-öncelikli): düz piksel düzlemini
  /// eğik düzleme taşır. Zemin dokusu/ızgara tek `save/transform` ile çizilebilir.
  Float64List canvasTransform() {
    final m = Float64List(16);
    m[0] = _m[0];
    m[1] = _m[3];
    m[2] = 0;
    m[3] = _m[6];
    m[4] = _m[1];
    m[5] = _m[4];
    m[6] = 0;
    m[7] = _m[7];
    m[8] = 0;
    m[9] = 0;
    m[10] = 1;
    m[11] = 0;
    m[12] = _m[2];
    m[13] = _m[5];
    m[14] = 0;
    m[15] = _m[8];
    return m;
  }

  static Offset _apply(List<double> m, double x, double y) {
    final xp = m[0] * x + m[1] * y + m[2];
    final yp = m[3] * x + m[4] * y + m[5];
    final w = m[6] * x + m[7] * y + m[8];
    return Offset(xp / w, yp / w);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Birim kare (0,0),(1,0),(1,1),(0,1) → dörtgen [q] homografisi (Heckbert).
  static List<double> _squareToQuad(List<Offset> q) {
    final x0 = q[0].dx, y0 = q[0].dy;
    final x1 = q[1].dx, y1 = q[1].dy;
    final x2 = q[2].dx, y2 = q[2].dy;
    final x3 = q[3].dx, y3 = q[3].dy;

    final sx = x0 - x1 + x2 - x3;
    final sy = y0 - y1 + y2 - y3;

    if (sx.abs() < 1e-9 && sy.abs() < 1e-9) {
      return [
        x1 - x0, x3 - x0, x0,
        y1 - y0, y3 - y0, y0,
        0, 0, 1,
      ];
    }

    final dx1 = x1 - x2, dx2 = x3 - x2;
    final dy1 = y1 - y2, dy2 = y3 - y2;
    final den = dx1 * dy2 - dx2 * dy1;
    final g = (sx * dy2 - dx2 * sy) / den;
    final h = (dx1 * sy - sx * dy1) / den;

    return [
      x1 - x0 + g * x1, x3 - x0 + h * x3, x0,
      y1 - y0 + g * y1, y3 - y0 + h * y3, y0,
      g, h, 1,
    ];
  }

  /// 3x3 satır-öncelikli matris tersi (ek matris / determinant).
  static List<double> _invert3(List<double> m) {
    final a = m[0], b = m[1], c = m[2];
    final d = m[3], e = m[4], f = m[5];
    final g = m[6], h = m[7], i = m[8];

    final ai = e * i - f * h;
    final bi = -(d * i - f * g);
    final ci = d * h - e * g;
    final det = a * ai + b * bi + c * ci;
    final inv = 1.0 / det;

    return [
      ai * inv, (c * h - b * i) * inv, (b * f - c * e) * inv,
      bi * inv, (a * i - c * g) * inv, (c * d - a * f) * inv,
      ci * inv, (b * g - a * h) * inv, (a * e - b * d) * inv,
    ];
  }
}
