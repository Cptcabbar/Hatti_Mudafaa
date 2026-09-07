import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:game_core/game_core.dart';

import '../settings.dart';
import 'board_metrics.dart';
import 'board_projection.dart';
import 'game_controller.dart';

/// Yerel oyunun Flame sahnesi. Şimdilik her kare durumdan yeniden çizilir;
/// Faz 2'de piyon/engel ayrı animasyonlu bileşenlere ayrılacak.
class HattiBoardGame extends FlameGame {
  HattiBoardGame(this.controller, {this.hotSeat = true});

  final GameController controller;

  /// `true` (hot-seat): tahta her sıra, sırası gelen oyuncuya doğru döner.
  /// `false` (yapay zeka / tek taraf): tahta sabit — yerel oyuncuya (P1) bakar.
  final bool hotSeat;

  late final BoardComponent board;

  @override
  Color backgroundColor() => const Color(0xFF0A0806);

  @override
  Future<void> onLoad() async {
    board = BoardComponent(controller, hotSeat: hotSeat);
    add(board);
  }
}

class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent(this.controller, {this.hotSeat = true});

  final GameController controller;

  /// bkz. [HattiBoardGame.hotSeat]
  final bool hotSeat;

  BoardMetrics? _metrics;
  BoardProjection? _projection;

  /// Bir kez üretilen sert zemin dokusu (çamur + benek + krater + ızgara +
  /// hedef sektörleri). Eğim izdüşümüyle her kare projeksiyondan geçirilir.
  Image? _groundImage;

  /// Bir kez üretilen uzak cephe silüeti (sırt hattı + kırık kazıklar).
  /// Uzak kenarın arkasında ekran uzayında çizilir; eğimle taraf değiştirir.
  Image? _envImage;

  /// Bir kez üretilen no man's land zemin katmanı (kraterler + tel yumakları +
  /// moloz + yan enkazlar). Ufkun yakın tarafında, tam genişlikte çizilir —
  /// tahtanın yanındaki boş kahverengi alanları doldurur; eğimle taraf değiştirir.
  Image? _groundLayerImage;

  /// Tahtanın çizim alanındaki sol-üst köşesi (viewport pikseli).
  Offset _origin = Offset.zero;
  double _boardSide = 0;

  /// Eğik tahtanın ekran uzayındaki sınır kutusu ([_rebuildProjection]'da
  /// güncellenir) — çevre katmanı uzak/yakın kenarı buradan bulur.
  Rect _boardScreenBounds = Rect.zero;

  /// -1..1 eğim; sıra değişince [update] içinde hedefe doğru animasyonlanır.
  double _tilt = 0;

  /// Ortam animasyonu için biriken süre (duman salınımı, toz driftı).
  double _t = 0;

  /// Uzak cephede yukarı süzülen kül/toz zerreleri ([_ensureMotes]).
  final List<_Mote> _motes = [];

  /// Sahanın üstüne düşen kül / kor — tahtadan sonra çizilir ([_ensureAsh]).
  final List<_Mote> _ash = [];

  /// Zerre çizimi için yeniden kullanılan boya (kare başına ayırma olmasın).
  final Paint _moteP = Paint();

  /// Engel (mayın/tel) çizimlerinde yeniden kullanılan boyalar — mayın/tel
  /// koyarken her kare onlarca `Paint()` ayırmak kasmaya yol açıyordu.
  final Paint _scarFleckP = Paint()..color = const Color(0x553A3024);
  final Paint _wireStrandP = Paint()..style = PaintingStyle.stroke;
  final Paint _wireBarbP = Paint()..strokeWidth = 1.3;

  /// Engel enkazının "dağılmış toprak" benekleri — çapa notasyonuna göre bir
  /// kez üretilir (konumlar eğimden bağımsız, düzlem-uzayında sabittir).
  final Map<String, List<(Offset, double)>> _scarFlecks = {};

  BoardMetrics? get metrics => _metrics;

  bool get _particlesOn => AppSettings.instance.particles.value;

  double get _targetTilt {
    // Yapay zeka / tek taraf modunda tahta hep yerel oyuncuya (P1) bakar;
    // sıra AI'da iken dönmez — oynanış birebir aynı kalır.
    if (!hotSeat) return 1.0;
    if (controller.isOver) return 0;
    return controller.turn == Player.p1 ? 1.0 : -1.0;
  }

  /// Ayakta duran öğelerin (asker, mayın çubukları, tel direkleri) tepe
  /// noktasının ekran-y ofseti. Eğim yönüyle işaret değiştirir — böylece
  /// hem tahta hem üstündeki her şey sırası gelen oyuncuya doğru "eğilir".
  /// Eğim düzken (flip animasyonu ortası) yükseklik kısalır: diorama dönüşü.
  double _liftY(double height) {
    final sign = _tilt == 0 ? -1.0 : -_tilt.sign;
    final mag = 0.28 + 0.72 * _tilt.abs();
    return sign * mag * height;
  }

  /// Dokular en son bu boyut için üretildi — aynı boyuta gelen tekrar
  /// resize'larda (web pencere sürüklemesi) yeniden bake etmeyi önler.
  Vector2? _bakedForSize;

  /// Bir kez üretilen yumuşak ışık lekesi (beyaz radyal degrade). Ateş
  /// parıltısı / flare / kor için — her karede `MaskFilter.blur` yerine.
  Image? _glowSprite;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();

    _boardSide = math.min(size.x * 1.02, size.y * 0.88);
    _metrics = BoardMetrics(
      boardSize: controller.state.config.boardSize,
      side: _boardSide,
    );
    if (_bakedForSize == null ||
        (size.x - _bakedForSize!.x).abs() > 1 ||
        (size.y - _bakedForSize!.y).abs() > 1) {
      _bakedForSize = size.clone();
      _bakeGround();
      _bakeEnvironment();
      _bakeGroundLayer();
      _glowSprite ??= _bakeGlowSprite();
    }
    _rebuildProjection();
  }

  @override
  void onRemove() {
    _groundImage?.dispose();
    _groundImage = null;
    _envImage?.dispose();
    _envImage = null;
    _groundLayerImage?.dispose();
    _groundLayerImage = null;
    _glowSprite?.dispose();
    _glowSprite = null;
    super.onRemove();
  }

  /// 128×128 beyaz radyal degrade (merkez opak → kenar şeffaf). Bir kez.
  Image _bakeGlowSprite() {
    final recorder = PictureRecorder();
    Canvas(recorder).drawCircle(
      const Offset(64, 64),
      64,
      Paint()
        ..shader = Gradient.radial(
          const Offset(64, 64),
          64,
          const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0.0, 1.0],
        ),
    );
    final pic = recorder.endRecording();
    final img = pic.toImageSync(128, 128);
    pic.dispose();
    return img;
  }

  /// Yumuşak ışık lekesi — [_glowSprite]'ı ölçekleyip renklendirerek çizer
  /// (blur yok). [color]'ın alfası yoğunluğu belirler.
  void _glowBlob(Canvas canvas, Offset center, double radius, Color color) {
    final s = _glowSprite;
    if (s == null || radius <= 0) return;
    canvas.drawImageRect(
      s,
      const Rect.fromLTWH(0, 0, 128, 128),
      Rect.fromCircle(center: center, radius: radius),
      Paint()
        ..colorFilter = ColorFilter.mode(color, BlendMode.modulate)
        ..filterQuality = FilterQuality.low,
    );
  }

  void _rebuildProjection() {
    if (_boardSide <= 0) return;
    final proj = BoardProjection(side: _boardSide, tilt: _tilt);
    _projection = proj;

    // Eğik tahtanın gerçek sınır kutusunu çizim alanında ortala (dikeyde biraz
    // yukarı — ayakta duran taşlara ve yakın kenar gölgesine pay).
    final corners = [
      proj.project(const Offset(0, 0)),
      proj.project(Offset(_boardSide, 0)),
      proj.project(Offset(_boardSide, _boardSide)),
      proj.project(Offset(0, _boardSide)),
    ];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final c in corners) {
      minX = math.min(minX, c.dx);
      maxX = math.max(maxX, c.dx);
      minY = math.min(minY, c.dy);
      maxY = math.max(maxY, c.dy);
    }
    // Tahtayı sırası gelen oyuncunun kenarına doğru kaydır: yakın kenar oyuncuya
    // yaklaşır, uzak tarafta cepheye yer açılır (siyah boşluk oraya toplanmaz).
    final nearBias = _tilt * size.y * 0.09;
    _origin = Offset(
      (size.x - (maxX - minX)) / 2 - minX,
      (size.y - (maxY - minY)) / 2 - minY - size.y * 0.01 + nearBias,
    );
    _boardScreenBounds = Rect.fromLTRB(
      _origin.dx + minX,
      _origin.dy + minY,
      _origin.dx + maxX,
      _origin.dy + maxY,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final target = _targetTilt;
    if ((_tilt - target).abs() > 1e-4) {
      // yumuşak, ~0.35 sn oturan yaklaşım
      _tilt += (target - _tilt) * math.min(1.0, dt * 8.0);
      if ((_tilt - target).abs() <= 1e-4) _tilt = target;
      _rebuildProjection();
    }
  }

  /// Düz tahta pikseli → viewport pikseli.
  Offset _p(Offset flat) => _origin + _projection!.project(flat);

  @override
  void onTapDown(TapDownEvent event) {
    final proj = _projection;
    final m = _metrics;
    if (proj == null || m == null) return;
    final flat = proj.unproject(event.localPosition.toOffset() - _origin);
    controller.tapBoard(flat, m);
  }

  @override
  void render(Canvas canvas) {
    final m = _metrics;
    final proj = _projection;
    if (m == null || proj == null) return;

    // Tahtanın oturduğu dünya — siyah boşluğu dolduran puslu uzak cephe.
    _drawEnvironment(canvas);

    final state = controller.state;
    final side = m.side;
    final cell = m.cell;

    // --- Zemin düzlemi: eğim izdüşümü altında çiz ---
    canvas.save();
    canvas.translate(_origin.dx, _origin.dy);
    canvas.transform(proj.canvasTransform());

    final img = _groundImage;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(0, 0, side, side),
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, side, side),
        Paint()..color = const Color(0xFF4E4231),
      );
    }

    // Derinlik gölgesi — uzak kenar koyu, yakın kenar hafif vinyet.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..shader = Gradient.linear(
          Offset(side / 2, 0),
          Offset(side / 2, side),
          _tilt >= 0
              ? const [Color(0x55000000), Color(0x08000000)]
              : const [Color(0x08000000), Color(0x55000000)],
        ),
    );

    // Yasal hamle vurguları.
    if (controller.mode == InteractionMode.move && !state.isOver) {
      final fill = Paint()..color = const Color(0x4048C774);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x9948C774);
      for (final sq in controller.legalStepTargets) {
        final g = m.cellCenter(sq);
        canvas.drawCircle(g, cell * 0.17, fill);
        canvas.drawCircle(g, cell * 0.17, ring);
      }
    }

    // Aktif askerin zemin nişanı (düzlemde — eğimle elips olur).
    if (!state.isOver) {
      final ac = m.cellCenter(state.pawnOf(state.turn));
      final rr = cell * 0.40;
      final reticle = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.035
        ..color = const Color(0xCCEDE7D6);
      canvas.drawCircle(ac, rr, reticle);
      for (final d in const [
        Offset(0, -1),
        Offset(0, 1),
        Offset(-1, 0),
        Offset(1, 0),
      ]) {
        canvas.drawLine(
          ac + Offset(d.dx * rr * 0.78, d.dy * rr * 0.78),
          ac + Offset(d.dx * rr * 1.18, d.dy * rr * 1.18),
          reticle,
        );
      }
    }

    // Engel yer izleri — kazılmış toprak (zemin düzleminde).
    final preview = controller.preview;
    for (final b in state.barriers) {
      _drawBarrierScar(canvas, m, b);
    }
    if (preview != null) {
      _drawBarrierScar(canvas, m, preview, ghost: true);
    }

    canvas.restore();

    // --- Dikey öğeler: derinliğe göre sıralı billboard ---
    // Büyük derinlik = yakın = sonra çizilir (üstte). Beraberlikte asker öne
    // gelsin (bitişik engelle üst üste gelince asker net kalır).
    double depthOf(Offset flat) => _tilt >= 0 ? flat.dy : -flat.dy;
    final items = <({double depth, void Function() draw})>[];

    for (final b in state.barriers) {
      final (a, z) = m.barrierLine(b);
      final mid = Offset.lerp(a, z, 0.5)!;
      items.add((
        depth: depthOf(mid),
        draw: () => b.isWire
            ? _drawWire(canvas, m, proj, b)
            : _drawMine(canvas, m, proj, b, preview: false, ok: true),
      ));
    }
    items
      ..add((
        depth: depthOf(m.cellCenter(state.pawnP1)) + cell * 0.02,
        draw: () => _drawSoldier(canvas, m, proj, state.pawnP1, _Faction.p1),
      ))
      ..add((
        depth: depthOf(m.cellCenter(state.pawnP2)) + cell * 0.02,
        draw: () => _drawSoldier(canvas, m, proj, state.pawnP2, _Faction.p2),
      ))
      ..sort((x, y) => x.depth.compareTo(y.depth));
    for (final it in items) {
      it.draw();
    }

    // Önizleme cihazı — her zaman en üstte.
    if (preview != null) {
      final ok = controller.canConfirmPreview;
      if (preview.isWire) {
        _drawWire(canvas, m, proj, preview, preview: true, ok: ok);
      } else {
        _drawMine(canvas, m, proj, preview, preview: true, ok: ok);
      }
    }

    // Sahanın üstüne düşen kül / kor — tahtanın ve taşların üstünde.
    _drawAshOverlay(canvas);

    // Çevre vinyeti — köşeleri hafifçe karart (en üstte, çok hafif). Shader
    // yalnızca boyut değişince yeniden kurulur (kare başına ayırma yok).
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _vignettePaint());
  }

  Paint? _vignetteCache;
  Vector2? _vignetteForSize;

  Paint _vignettePaint() {
    if (_vignetteCache == null ||
        _vignetteForSize == null ||
        _vignetteForSize!.x != size.x ||
        _vignetteForSize!.y != size.y) {
      _vignetteForSize = size.clone();
      _vignetteCache = Paint()
        ..shader = Gradient.radial(
          Offset(size.x / 2, size.y * 0.46),
          size.length * 0.6,
          const [Color(0x00000000), Color(0x4F080604)],
          const [0.58, 1.0],
        );
    }
    return _vignetteCache!;
  }

  // ---------------------------------------------------------------------------
  // Zemin dokusu (bir kez üretilir)
  // ---------------------------------------------------------------------------

  void _bakeGround() {
    final m = _metrics;
    if (m == null || _boardSide <= 0) return;
    _groundImage?.dispose();

    const scale = 2.0;
    final n = m.boardSize;
    final side = _boardSide;
    final cell = m.cell;
    final px = (side * scale).ceil();

    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    c.scale(scale);
    final rnd = math.Random(20260906);

    // 1) Islak toprak taban degradesi.
    c.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, side),
          const [Color(0xFF645644), Color(0xFF4A3E2E)],
        ),
    );

    // 2a) Geniş açık kuru/kabarık alanlar (büyük tonal dalga).
    for (var i = 0; i < 12; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        cell * (0.7 + rnd.nextDouble() * 1.4),
        Paint()
          ..color = Color.fromRGBO(146, 128, 96, 0.05 + rnd.nextDouble() * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
    // 2b) Geniş koyu çamur birikintileri.
    for (var i = 0; i < 40; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        cell * (0.25 + rnd.nextDouble() * 0.9),
        Paint()
          ..color = Color.fromRGBO(26, 20, 13, 0.07 + rnd.nextDouble() * 0.11)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    // Açık kuru toz smear'ları.
    for (var i = 0; i < 18; i++) {
      c
        ..save()
        ..translate(rnd.nextDouble() * side, rnd.nextDouble() * side)
        ..rotate((rnd.nextDouble() - 0.5) * math.pi)
        ..drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: cell * (0.6 + rnd.nextDouble() * 1.6),
            height: cell * (0.10 + rnd.nextDouble() * 0.22),
          ),
          Paint()
            ..color =
                Color.fromRGBO(154, 136, 102, 0.04 + rnd.nextDouble() * 0.05)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        )
        ..restore();
    }

    // 3) Grain — ufak taş / is benekleri.
    for (var i = 0; i < 2400; i++) {
      final dark = rnd.nextInt(3) != 0;
      c.drawCircle(
        Offset(rnd.nextDouble() * side, rnd.nextDouble() * side),
        0.6 + rnd.nextDouble() * 1.7,
        Paint()
          ..color = dark
              ? Color.fromRGBO(18, 14, 9, 0.06 + rnd.nextDouble() * 0.20)
              : Color.fromRGBO(158, 142, 110, 0.05 + rnd.nextDouble() * 0.12),
      );
    }

    // 4) Kraterler (sabit yerleşim) — düzensiz koyu ezikler, geometrik halka yok.
    final cr = math.Random(31);
    for (var i = 0; i < 5; i++) {
      final p = Offset(
        side * (0.14 + 0.72 * cr.nextDouble()),
        side * (0.14 + 0.72 * cr.nextDouble()),
      );
      final rad = cell * (0.5 + cr.nextDouble() * 0.6);
      for (var k = 0; k < 3; k++) {
        final off = Offset(
          (cr.nextDouble() - 0.5) * rad * 0.7,
          (cr.nextDouble() - 0.5) * rad * 0.7,
        );
        c.drawCircle(
          p + off,
          rad * (0.55 + cr.nextDouble() * 0.5),
          Paint()
            ..color = Color.fromRGBO(15, 10, 6, 0.14 + cr.nextDouble() * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      // Saçılmış toprak (kraterin bir yanında hafif açık).
      c.drawCircle(
        p + Offset(rad * 0.6, -rad * 0.5),
        rad * 0.7,
        Paint()
          ..color = const Color(0x14A08A64)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // 5) Hedef sektörleri (üst = mavi P1 hedefi, alt = kırmızı P2 hedefi).
    _bakeSector(
        c, Rect.fromLTWH(0, 0, side, cell), const Color(0xFF3E6E9E), atTop: true);
    _bakeSector(c, Rect.fromLTWH(0, side - cell, side, cell),
        const Color(0xFFA2433B),
        atTop: false);

    // 6) Yıpranmış ızgara.
    for (var i = 0; i <= n; i++) {
      _wornGridLine(c, Offset(i * cell, 0), Offset(i * cell, side), rnd);
      _wornGridLine(c, Offset(0, i * cell), Offset(side, i * cell), rnd);
    }

    // 7) İç sınır — parapet (siper duvarı) gölgesi + kenar dudağı ışığı.
    c
      ..drawRect(
        Rect.fromLTWH(0, 0, side, side).deflate(cell * 0.04),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.14
          ..color = const Color(0x4D000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRect(
        Rect.fromLTWH(0, 0, side, side),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x59140D08),
      );
    // Üst ve alt siper kenarında hafif yakalanan ışık.
    for (final atTop in const [true, false]) {
      final y = atTop ? 0.0 : side;
      c.drawRect(
        Rect.fromLTWH(0, y - (atTop ? 0 : cell * 0.5), side, cell * 0.5),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, atTop ? 0 : side),
            Offset(0, atTop ? cell * 0.5 : side - cell * 0.5),
            const [Color(0x1FA79068), Color(0x00A79068)],
          ),
      );
    }

    final picture = recorder.endRecording();
    _groundImage = picture.toImageSync(px, px);
    picture.dispose();
  }

  void _bakeSector(Canvas c, Rect r, Color color, {required bool atTop}) {
    c.drawRect(r, Paint()..color = color.withValues(alpha: 0.17));

    // Çapraz tehlike şeritleri.
    c
      ..save()
      ..clipRect(r);
    final stripe = Paint()
      ..color = color.withValues(alpha: 0.09)
      ..strokeWidth = r.height * 0.34;
    for (var x = -r.height; x < r.width + r.height; x += r.height * 0.9) {
      c.drawLine(
        Offset(r.left + x, r.top),
        Offset(r.left + x + r.height, r.bottom),
        stripe,
      );
    }
    c.restore();

    // Hedef kenarında şablon (stencil) kesikli çizgi.
    final y = atTop ? r.bottom - 2.5 : r.top + 2.5;
    final dash = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    const segs = 26;
    for (var i = 0; i < segs; i += 2) {
      final x0 = r.left + r.width * i / segs;
      c.drawLine(Offset(x0, y), Offset(x0 + r.width / segs * 0.7, y), dash);
    }
  }

  void _wornGridLine(Canvas c, Offset a, Offset b, math.Random rnd) {
    const segs = 12;
    final dark = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = const Color(0xA32A2118);
    final lip = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1
      ..color = const Color(0x30837155);
    for (var s = 0; s < segs; s++) {
      if (rnd.nextDouble() < 0.10) continue;
      Offset j() => Offset(
            (rnd.nextDouble() - 0.5) * 2.2,
            (rnd.nextDouble() - 0.5) * 2.2,
          );
      final p0 = Offset.lerp(a, b, s / segs)! + j();
      final p1 = Offset.lerp(a, b, (s + 1) / segs)! + j();
      c
        ..drawLine(p0, p1, dark)
        ..drawLine(p0.translate(-0.7, -0.7), p1.translate(-0.7, -0.7), lip);
    }
  }

  // ---------------------------------------------------------------------------
  // Çevre / atmosfer (tahtanın etrafındaki siyah boşluğu dolduran uzak cephe)
  // ---------------------------------------------------------------------------

  /// Uzak cephenin katmanlı silüetini bir kez image'e üretir: uzak sırt
  /// hatları + parçalanmış ağaçlar + yıkık sığınak + dikenli tel engeli +
  /// kırık kazık tarlası + devrik top arabası + mermi kraterleri. Şeffaf
  /// zemin; render'da uzak kenarın arkasına yerleştirilir (ekran uzayında).
  void _bakeEnvironment() {
    if (size.x <= 0 || size.y <= 0) return;
    _envImage?.dispose();

    const scale = 2.0;
    final w = size.x;
    final h = size.y * 0.5;
    final recorder = PictureRecorder();
    final c = Canvas(recorder)..scale(scale);
    final rnd = math.Random(20260907);

    // Görüntü koordinatı: y=0 gökyüzü (yukarı), y=h ufuk (tahtanın uzak kenarı).

    // 1) Katmanlı sırt hatları (arkadan öne: soluk+bulanık → koyu+net).
    Path ridge(double baseFrac, double amp, int bumps) {
      final topBase = h * baseFrac;
      final p = Path()
        ..moveTo(0, h + 4)
        ..lineTo(0, topBase);
      for (var i = 1; i <= bumps; i++) {
        final x = w * i / bumps;
        final y = topBase + (rnd.nextDouble() - 0.5) * amp;
        final cx = w * (i - 0.5) / bumps;
        p.quadraticBezierTo(cx, y - amp * 0.55, x, y);
      }
      return p
        ..lineTo(w, h + 4)
        ..close();
    }

    c
      ..drawPath(
        ridge(0.44, h * 0.14, 6),
        Paint()
          ..color = const Color(0x78100D09)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawPath(
        ridge(0.57, h * 0.13, 7),
        Paint()
          ..color = const Color(0xA00C0A07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      )
      ..drawPath(ridge(0.71, h * 0.12, 6), Paint()..color = const Color(0xC80A0806));

    // 2) Parçalanmış ağaçlar (orta sırt üstünde — kırık, çıralı zirveler).
    void shatteredTree(double x, double baseY, double th) {
      final lean = (rnd.nextDouble() - 0.5) * th * 0.22;
      final top = x + lean;
      c.drawPath(
        Path()
          ..moveTo(x - th * 0.055, baseY)
          ..lineTo(x + th * 0.045, baseY)
          ..lineTo(top + th * 0.03, baseY - th)
          ..lineTo(top + th * 0.13, baseY - th * 0.84)
          ..lineTo(top - th * 0.02, baseY - th * 0.74)
          ..lineTo(top - th * 0.1, baseY - th * 0.9)
          ..lineTo(top - th * 0.03, baseY - th)
          ..close(),
        Paint()..color = const Color(0xD4070503),
      );
      if (rnd.nextBool()) {
        final dir = rnd.nextBool() ? 1.0 : -1.0;
        c.drawLine(
          Offset(top, baseY - th * 0.6),
          Offset(top + dir * th * 0.32, baseY - th * 0.46),
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = th * 0.05
            ..color = const Color(0xCC060402),
        );
      }
    }

    for (var i = 0; i < 6; i++) {
      shatteredTree(
        w * (0.05 + 0.9 * rnd.nextDouble()),
        h * (0.65 + 0.06 * rnd.nextDouble()),
        h * (0.16 + rnd.nextDouble() * 0.14),
      );
    }

    // 3) Yıkık sığınak / duvar (çökmüş, devrik kirişli).
    {
      final x = w * (0.18 + 0.5 * rnd.nextDouble());
      final by = h * 0.72;
      final bw = h * 0.34;
      final bh = h * 0.2;
      c
        ..drawPath(
          Path()
            ..moveTo(x, by)
            ..lineTo(x, by - bh * 0.68)
            ..lineTo(x + bw * 0.4, by - bh)
            ..lineTo(x + bw * 0.72, by - bh * 0.52)
            ..lineTo(x + bw, by - bh * 0.82)
            ..lineTo(x + bw, by)
            ..close(),
          Paint()..color = const Color(0xDE060402),
        )
        ..drawLine(
          Offset(x + bw * 0.18, by - bh * 0.55),
          Offset(x + bw * 1.12, by - bh * 0.06),
          Paint()
            ..strokeWidth = h * 0.02
            ..color = const Color(0xC8050301),
        );
    }

    // 4) Dikenli tel engeli — sıra kazık + tepeleri arasında sarkan 3 tel.
    {
      const n = 12;
      final wy = h * 0.85;
      final tops = <Offset>[];
      for (var i = 0; i <= n; i++) {
        final x = w * i / n + (rnd.nextDouble() - 0.5) * w * 0.02;
        final ph = h * (0.055 + rnd.nextDouble() * 0.05);
        final lean = (rnd.nextDouble() - 0.5) * 0.5;
        final top = Offset(x + math.sin(lean) * ph, wy - ph);
        tops.add(top);
        c.drawLine(
          Offset(x, wy),
          top,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.1
            ..color = const Color(0xE0060402),
        );
      }
      for (var s = 0; s < 3; s++) {
        final sag = h * (0.014 + s * 0.011);
        final path = Path()..moveTo(tops.first.dx, tops.first.dy + s * 1.8);
        for (var i = 1; i < tops.length; i++) {
          final a = tops[i - 1];
          final b = tops[i];
          path.quadraticBezierTo(
            (a.dx + b.dx) / 2,
            math.max(a.dy, b.dy) + sag + s * 1.8,
            b.dx,
            b.dy + s * 1.8,
          );
        }
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = const Color(0x8C050301),
        );
      }
    }

    // 5) Kırık kazık tarlası (yoğun, yakın — no man's land).
    for (var i = 0; i < 22; i++) {
      final x = w * (0.01 + 0.98 * rnd.nextDouble());
      final rootY = h * (0.85 + 0.16 * rnd.nextDouble());
      final len = h * (0.05 + rnd.nextDouble() * 0.2);
      final lean = (rnd.nextDouble() - 0.5) * 0.8;
      final tip = Offset(x + math.sin(lean) * len, rootY - math.cos(lean) * len);
      c.drawLine(
        Offset(x, rootY),
        tip,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.4 + rnd.nextDouble() * 2.4
          ..color = const Color(0xE6050301),
      );
      if (rnd.nextDouble() < 0.35) {
        final mid =
            Offset.lerp(Offset(x, rootY), tip, 0.5 + rnd.nextDouble() * 0.3)!;
        final perp = Offset(math.cos(lean), math.sin(lean)) * (len * 0.16);
        c.drawLine(
          mid - perp,
          mid + perp,
          Paint()
            ..strokeWidth = 1
            ..color = const Color(0x99040301),
        );
      }
    }

    // 6) Devrik top arabası (tekerlek + namlu silüeti).
    {
      final wheel = h * 0.06;
      c
        ..save()
        ..translate(
          w * (0.12 + 0.7 * rnd.nextDouble()),
          h * (0.92 + rnd.nextDouble() * 0.04),
        )
        ..rotate((rnd.nextDouble() - 0.5) * 0.5);
      final dark = Paint()..color = const Color(0xF0060402);
      c
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-wheel * 1.6, -wheel * 0.5, wheel * 3.2, wheel * 0.7),
            Radius.circular(wheel * 0.2),
          ),
          dark,
        )
        ..drawLine(
          Offset(0, -wheel * 0.3),
          Offset(wheel * 2.6, -wheel * 1.1),
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = wheel * 0.3
            ..color = const Color(0xF0060402),
        );
      for (final wx in [-wheel * 1.3, wheel * 1.3]) {
        c.drawCircle(
          Offset(wx, 0),
          wheel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = const Color(0xF0060402),
        );
        for (var k = 0; k < 6; k++) {
          final ang = k * math.pi / 3;
          c.drawLine(
            Offset(wx, 0),
            Offset(wx + math.cos(ang) * wheel, math.sin(ang) * wheel),
            Paint()
              ..strokeWidth = 1.2
              ..color = const Color(0xF0060402),
          );
        }
      }
      c.restore();
    }

    // 7) Mermi kraterleri (tahtanın uzak kenarına değen zeminde).
    for (var i = 0; i < 4; i++) {
      final rw = h * (0.06 + rnd.nextDouble() * 0.05);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.1 + 0.8 * rnd.nextDouble()),
              h * (0.96 + rnd.nextDouble() * 0.04)),
          width: rw * 2.4,
          height: rw,
        ),
        Paint()
          ..color = const Color(0x66040302)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    final picture = recorder.endRecording();
    _envImage = picture.toImageSync((w * scale).ceil(), (h * scale).ceil());
    picture.dispose();
  }

  /// No man's land zemin katmanı — tam viewport genişliğinde, ufkun yakın
  /// tarafında. Kraterler + tel yumakları + moloz + kenarlarda büyük enkaz.
  /// Tahtanın yanındaki / önündeki boş kahverengi alanları doldurur.
  void _bakeGroundLayer() {
    if (size.x <= 0 || size.y <= 0) return;
    _groundLayerImage?.dispose();

    const scale = 2.0;
    final w = size.x;
    final h = size.y; // ufuktan en yakın kenara — tam yükseklik güvenli
    final recorder = PictureRecorder();
    final c = Canvas(recorder)..scale(scale);
    final rnd = math.Random(556677);

    // Görüntü: y=0 ufuk (şeffafa yakın), y=h en yakın (koyu). Çamurlu taban.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, 0),
          Offset(0, h),
          const [Color(0x00000000), Color(0xE0261B0F), Color(0xF01B1409)],
          const [0.0, 0.13, 1.0],
        ),
    );

    // Geniş tonal dalgalar (kuru/ıslak yamalar) — yumuşak radyal, blur yok.
    for (var i = 0; i < 10; i++) {
      final ny = 0.14 + 0.84 * rnd.nextDouble();
      final cx = w * (rnd.nextDouble() * 1.1 - 0.05);
      final cy = h * ny;
      final rad = h * (0.06 + 0.11 * rnd.nextDouble());
      final col = rnd.nextBool()
          ? Color.fromRGBO(20, 15, 9, 0.16 + rnd.nextDouble() * 0.16)
          : Color.fromRGBO(120, 104, 78, 0.035 + rnd.nextDouble() * 0.045);
      c.drawCircle(
        Offset(cx, cy),
        rad,
        Paint()
          ..shader = Gradient.radial(Offset(cx, cy), rad, [col, col.withAlpha(0)]),
      );
    }

    // Mermi kraterleri — yakına doğru büyür; hafif izci-yanı ışığı.
    for (var i = 0; i < 11; i++) {
      final ny = 0.16 + 0.8 * rnd.nextDouble();
      final cx = w * (rnd.nextDouble() * 1.12 - 0.06);
      final cy = h * ny;
      final rad = h * (0.028 + 0.055 * ny) * (0.7 + rnd.nextDouble() * 0.8);
      final r = Rect.fromCenter(
        center: Offset(cx, cy),
        width: rad * 2.7,
        height: rad * 1.5,
      );
      c
        ..drawOval(
          r,
          Paint()
            ..color = const Color(0x9E100C07)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.45),
        )
        ..drawArc(
          r,
          0.25,
          math.pi - 0.5,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = rad * 0.14
            ..color = const Color(0x22A8906A),
        );
    }

    // Dikenli tel yumakları — kaotik kısa çizgi kümeleri.
    for (var i = 0; i < 9; i++) {
      final cx = w * (rnd.nextDouble() * 1.12 - 0.06);
      final cy = h * (0.2 + 0.74 * rnd.nextDouble());
      final rad = h * (0.02 + 0.035 * rnd.nextDouble());
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0x8C0B0805);
      for (var k = 0; k < 10; k++) {
        final a0 = rnd.nextDouble() * math.pi * 2;
        final a1 = a0 + 0.7 + rnd.nextDouble() * 2.2;
        c.drawLine(
          Offset(cx + math.cos(a0) * rad, cy + math.sin(a0) * rad * 0.5),
          Offset(cx + math.cos(a1) * rad * 1.3, cy + math.sin(a1) * rad * 0.65),
          p,
        );
      }
    }

    // Moloz — kısa koyu çubuk / kalas parçaları.
    for (var i = 0; i < 26; i++) {
      final len = h * (0.012 + 0.03 * rnd.nextDouble());
      c
        ..save()
        ..translate(w * rnd.nextDouble(), h * (0.18 + 0.8 * rnd.nextDouble()))
        ..rotate((rnd.nextDouble() - 0.5) * math.pi)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: len, height: len * 0.26),
            const Radius.circular(1.5),
          ),
          Paint()..color = const Color(0xC00A0705),
        )
        ..restore();
    }

    // İki büyük yan enkaz — kenar bölgelerine odak (yıkık araç / sığınak).
    for (final side in const [0.09, 0.91]) {
      final cx = w * side;
      final cy = h * (0.4 + 0.14 * rnd.nextDouble());
      final ww = h * 0.13;
      final hh = h * 0.085;
      c
        ..drawPath(
          Path()
            ..moveTo(cx - ww, cy)
            ..lineTo(cx - ww * 0.78, cy - hh)
            ..lineTo(cx + ww * 0.15, cy - hh * 1.25)
            ..lineTo(cx + ww * 0.9, cy - hh * 0.5)
            ..lineTo(cx + ww, cy)
            ..close(),
          Paint()..color = const Color(0xD40A0705),
        )
        ..drawCircle(
          Offset(cx - ww * 0.5, cy + hh * 0.15),
          hh * 0.55,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..color = const Color(0xD40A0705),
        );
    }

    // Kenar karartma — yanları çerçevele (dikkat merkeze).
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, 0),
          Offset(w, 0),
          const [
            Color(0x73000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x73000000),
          ],
          const [0.0, 0.16, 0.84, 1.0],
        ),
    );

    final picture = recorder.endRecording();
    _groundLayerImage =
        picture.toImageSync((w * scale).ceil(), (h * scale).ceil());
    picture.dispose();
  }

  void _ensureMotes() {
    if (_motes.isNotEmpty) return;
    final rnd = math.Random(4477);
    for (var i = 0; i < 14; i++) {
      final ember = i % 6 == 0;
      _motes.add(_Mote(
        rnd.nextDouble(),
        rnd.nextDouble(),
        ember ? 1.0 + rnd.nextDouble() * 1.3 : 0.6 + rnd.nextDouble() * 1.3,
        (ember ? 3 : 5) + rnd.nextDouble() * (ember ? 6 : 11),
        4 + rnd.nextDouble() * 10,
        rnd.nextDouble() * math.pi * 2,
        ember ? 0.1 + rnd.nextDouble() * 0.07 : 0.05 + rnd.nextDouble() * 0.06,
        ember,
      ));
    }
  }

  /// Çevreyi (ekran uzayında, tahtadan önce) çizer: ölü gökyüzü + katmanlı
  /// sürüklenen pus + ufuk parıltısı/flare + uzak cephe silüeti + duman
  /// sütunları + kül/kor zerreleri + yakın kum torbası siperi.
  void _drawEnvironment(Canvas canvas) {
    final vw = size.x;
    final vh = size.y;
    if (vw <= 0 || vh <= 0) return;

    // Eğim işareti uzak kenarı belirler: >=0 → üst, <0 → alt.
    final farAtTop = _tilt >= -0.02;
    final rawFarY =
        farAtTop ? _boardScreenBounds.top : _boardScreenBounds.bottom;
    final farY = rawFarY.clamp(vh * 0.08, vh * 0.92);
    final up = farAtTop ? -1.0 : 1.0; // "gökyüzü" (uzak taraftan yukarı) yönü
    final envO = ((_tilt.abs() - 0.08) / 0.92).clamp(0.0, 1.0);

    // 1) Ölü kapalı-hava gökyüzü.
    final hy = (farY / vh).clamp(0.08, 0.92);
    canvas.drawRect(
      Offset.zero & Size(vw, vh),
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, 0),
          Offset(0, vh),
          const [Color(0xFF181109), Color(0xFF3B3221), Color(0xFF1B140A)],
          [0.0, hy, 1.0],
        ),
    );

    // 1b) No man's land zemin katmanı — ufkun yakın tarafında, tam genişlikte.
    //     Tahtanın yanındaki / önündeki boş kahverengi alanları doldurur.
    final ground = _groundLayerImage;
    if (ground != null) {
      final gsrc = Rect.fromLTWH(
          0, 0, ground.width.toDouble(), ground.height.toDouble());
      final gpaint = Paint()..filterQuality = FilterQuality.low;
      canvas.save();
      if (farAtTop) {
        canvas
          ..translate(0, farY)
          ..drawImageRect(
              ground, gsrc, Rect.fromLTWH(0, 0, vw, vh), gpaint);
      } else {
        canvas
          ..translate(vw, farY)
          ..rotate(math.pi)
          ..drawImageRect(
              ground, gsrc, Rect.fromLTWH(0, 0, vw, vh), gpaint);
      }
      canvas.restore();
    }

    // 2) Ufuk parıltısı + ara ara flare titremesi (silüetleri arkadan aydınlatır).
    final flare = 0.5 + 0.5 * math.sin(_t * 0.9);
    final band = vh * 0.18;
    canvas.drawRect(
      Rect.fromLTRB(0, farY - band, vw, farY + band),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, farY - band),
          Offset(0, farY + band),
          [
            const Color(0x00000000),
            Color.fromRGBO(112, 90, 52, 0.34 + 0.14 * flare * envO),
            const Color(0x00000000),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    // 3) Uzak cephe silüeti (bake) — uzak kenarın arkasında; eğimle döner.
    final img = _envImage;
    if (img != null && envO > 0.01) {
      final bandH = vh * 0.5;
      final src =
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final paint = Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, envO);
      canvas.save();
      if (farAtTop) {
        canvas
          ..translate(0, farY - bandH)
          ..drawImageRect(img, src, Rect.fromLTWH(0, 0, vw, bandH), paint);
      } else {
        // Alt kenarda: 180° döndür — karşı oyuncunun bakışında "yukarı" doğru.
        canvas
          ..translate(vw, farY + bandH)
          ..rotate(math.pi)
          ..drawImageRect(img, src, Rect.fromLTWH(0, 0, vw, bandH), paint);
      }
      canvas.restore();
    }

    // 3b) Yanan enkaz — tahtanın DIŞINDA kalan zeminde: iki yakın şerit ateşi
    //     (tahtanın yakın kenarının hemen ötesinde) + iki yan ateş (uzak
    //     köşelerde). Tahta bunların üstüne çizildiği için sahayı örtmezler.
    if (_particlesOn && envO > 0.02) {
      final toNear = farAtTop ? 1.0 : -1.0;
      // Ateşler tahtanın DIŞINDA, yan/köşe bölgelerinde — tahta üste
      // çizildiğinden sahayı örtmezler. Geniş ekranda yan boşlukları,
      // dar ekranda uzak köşe kamalarını doldururlar.
      _drawFire(canvas, vw * 0.05, farY + toNear * vh * 0.11, vh * 0.06, 0.05,
          envO, up);
      _drawFire(canvas, vw * 0.95, farY + toNear * vh * 0.09, vh * 0.052, 0.95,
          envO, up);
      _drawFire(canvas, vw * 0.06, farY + toNear * vh * 0.44, vh * 0.075, 0.28,
          envO, up);
      _drawFire(canvas, vw * 0.94, farY + toNear * vh * 0.5, vh * 0.065, 0.72,
          envO, up);
    }

    // 4) Katmanlı sürüklenen pus (yatay bantlar, yavaş yanal kayar).
    if (_particlesOn && envO > 0.01) {
      for (var i = 0; i < 2; i++) {
        final fy = farY + up * vh * (0.06 + i * 0.12);
        final drift = math.sin(_t * (0.12 + i * 0.05) + i * 2.0) * vw * 0.12;
        final fh = vh * (0.05 + i * 0.016);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(vw / 2 + drift, fy),
            width: vw * 2.3,
            height: fh,
          ),
          Paint()
            ..shader = Gradient.linear(
              Offset(0, fy - fh / 2),
              Offset(0, fy + fh / 2),
              [
                const Color(0x00000000),
                Color.fromRGBO(48, 43, 34, (0.08 - i * 0.017) * envO),
                const Color(0x00000000),
              ],
              const [0.0, 0.5, 1.0],
            ),
        );
      }
    }

    // 5) Uzak duman sütunları — 2 adet (yakın ateşlerin kendi dumanı ayrıca var).
    if (_particlesOn && envO > 0.01) {
      const cols = [
        (fx: 0.30, ph: 0.34, a: 0.24, spd: 0.4, wd: 0.08),
        (fx: 0.68, ph: 0.24, a: 0.18, spd: 0.55, wd: 0.06),
      ];
      for (final s in cols) {
        final sx = vw * s.fx;
        final baseY = farY + up * vh * 0.02;
        final tipY = baseY + up * vh * s.ph;
        final sway = math.sin(_t * s.spd + s.fx * 12) * vw * 0.06;
        final midY = (baseY + tipY) / 2;
        canvas.drawPath(
          Path()
            ..moveTo(sx - vw * s.wd, baseY)
            ..quadraticBezierTo(sx - vw * s.wd * 1.4 + sway, midY, sx + sway, tipY)
            ..quadraticBezierTo(
                sx + vw * s.wd * 1.4 + sway, midY, sx + vw * s.wd, baseY)
            ..close(),
          Paint()
            ..shader = Gradient.linear(
              Offset(sx, baseY),
              Offset(sx, tipY),
              [Color.fromRGBO(38, 34, 27, s.a * envO), const Color(0x00221C16)],
            ),
        );
      }
      // Ufuk boyunca alçak sürüklenen duman perdesi — degrade, blur yok.
      final lowY = farY + up * vh * 0.02;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(vw / 2 + math.sin(_t * 0.2) * vw * 0.1, lowY),
          width: vw * 2.0,
          height: vh * 0.16,
        ),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, lowY - vh * 0.08),
            Offset(0, lowY + vh * 0.08),
            [
              const Color(0x00000000),
              Color.fromRGBO(20, 17, 13, 0.2 * envO),
              const Color(0x00000000),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // 6) Uzak flare / patlama titremesi — nadir ısı bloomu (ışık lekesi).
    if (_particlesOn && envO > 0.01) {
      for (var i = 0; i < 2; i++) {
        final pulse = math
            .pow(math.max(0.0, math.sin(_t * (0.7 + i * 0.3) + i * 3.0)), 12)
            .toDouble();
        if (pulse < 0.02) continue;
        _glowBlob(
          canvas,
          Offset(vw * (i == 0 ? 0.32 : 0.74), farY + up * vh * 0.04),
          vh * 0.09,
          Color.fromRGBO(240, 158, 78, 0.18 * pulse * envO),
        );
      }
    }

    // 7) Kül / kor zerreleri (uzak cephede yukarı süzülen ortam tozu).
    if (_particlesOn) {
      _ensureMotes();
      final cycle = vh + 40;
      final moteP = _moteP;
      for (final mte in _motes) {
        final yy =
            (((mte.ny * cycle - _t * mte.spd) % cycle) + cycle) % cycle - 20;
        final xx = mte.nx * vw + math.sin(_t * 0.5 + mte.phase) * mte.amp;
        moteP.color = mte.ember
            ? Color.fromRGBO(216, 132, 66,
                mte.a * (0.55 + 0.45 * math.sin(_t * 3 + mte.phase)))
            : Color.fromRGBO(138, 126, 98, mte.a);
        canvas.drawCircle(Offset(xx, yy), mte.r, moteP);
      }
    }

    // 8) Yakın ön plan — SADECE tahtanın yakın kenarında ince bir gölge dudağı.
    //    Ekran kenarına (oyuncunun panel/kontrol tarafına) doğru hızla kaybolur;
    //    kontrolleri asla örtmez.
    final fg = _tilt.abs();
    if (fg > 0.05) {
      final boardNearY =
          farAtTop ? _boardScreenBounds.bottom : _boardScreenBounds.top;
      final dir = farAtTop ? 1.0 : -1.0;
      final outer = boardNearY + dir * vh * 0.07;
      canvas.drawRect(
        Rect.fromLTRB(
          0,
          math.min(boardNearY, outer) - 1,
          vw,
          math.max(boardNearY, outer) + 1,
        ),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, boardNearY),
            Offset(0, outer),
            [Color.fromRGBO(6, 4, 2, 0.5 * fg), const Color(0x00060402)],
          ),
      );
    }
  }

  void _ensureAsh() {
    if (_ash.isNotEmpty) return;
    final rnd = math.Random(90190);
    for (var i = 0; i < 22; i++) {
      final ember = i % 5 == 0;
      _ash.add(_Mote(
        rnd.nextDouble(),
        rnd.nextDouble(),
        ember ? 2.0 + rnd.nextDouble() * 2.4 : 1.2 + rnd.nextDouble() * 2.8,
        7 + rnd.nextDouble() * 15, // düşme hızı (px/sn)
        6 + rnd.nextDouble() * 18, // yanal salınım genliği
        rnd.nextDouble() * math.pi * 2,
        ember ? 0.3 + rnd.nextDouble() * 0.16 : 0.16 + rnd.nextDouble() * 0.14,
        ember,
      ));
    }
  }

  /// Sahanın (tahtanın + taşların) üstüne yavaşça düşen kül ve titreşen kor
  /// zerreleri. Ekran uzayında, [render] sonunda çizilir (blur yok). "Partiküller"
  /// ayarı kapalıysa hiç çizilmez.
  void _drawAshOverlay(Canvas canvas) {
    if (!_particlesOn) return;
    final vw = size.x;
    final vh = size.y;
    if (vw <= 0 || vh <= 0) return;
    _ensureAsh();
    final cycle = vh + 40;
    final p = _moteP;
    for (final a in _ash) {
      final yy = (((a.ny * cycle + _t * a.spd) % cycle) + cycle) % cycle - 20;
      final xx = a.nx * vw +
          math.sin(_t * 0.6 + a.phase) * a.amp +
          math.sin(_t * 1.7 + a.phase * 2) * a.amp * 0.3;
      if (a.ember) {
        final gl = 0.5 + 0.5 * math.sin(_t * 5 + a.phase);
        _glowBlob(
          canvas,
          Offset(xx, yy),
          a.r * (1.9 + 0.6 * gl),
          Color.fromRGBO(244, 150, 66, a.a * (0.42 + 0.5 * gl)),
        );
      } else {
        p.color = Color.fromRGBO(166, 156, 136, a.a);
        canvas.drawCircle(Offset(xx, yy), a.r, p);
      }
    }
  }

  /// Tek bir yanan enkaz noktası: yer parıltısı + oynayan alev dilleri +
  /// ince yükselen duman. [up] alevin yükseldiği ekran yönü (eğime göre).
  void _drawFire(
    Canvas canvas,
    double fx,
    double fy,
    double sc,
    double seed,
    double envO,
    double up,
  ) {
    final flick = 0.6 +
        0.26 * math.sin(_t * 12 + seed * 40) +
        0.14 * math.sin(_t * 27 + seed * 13);

    // Yere vuran sıcak parıltı — bake edilmiş ışık lekesi (blur yok).
    _glowBlob(
      canvas,
      Offset(fx, fy),
      sc * (3.0 + 0.8 * flick),
      Color.fromRGBO(240, 132, 52, 0.24 * flick * envO),
    );

    // İnce yükselen duman — degrade dolgulu, blur yok.
    final st = fy + up * sc * 3.4;
    final drift = math.sin(_t * 0.6 + seed * 6) * sc * 1.8;
    canvas.drawPath(
      Path()
        ..moveTo(fx - sc * 0.7, fy)
        ..quadraticBezierTo(fx - sc + drift, (fy + st) / 2, fx + drift, st)
        ..quadraticBezierTo(fx + sc + drift, (fy + st) / 2, fx + sc * 0.7, fy)
        ..close(),
      Paint()
        ..shader = Gradient.linear(
          Offset(fx, fy),
          Offset(fx, st),
          [Color.fromRGBO(30, 26, 21, 0.16 * envO), const Color(0x00000000)],
        ),
    );

    // Alev dilleri — degrade dolgulu üçgen diller, blur yok.
    for (var i = 0; i < 4; i++) {
      final lf = 0.4 + 0.6 * math.sin(_t * (8 + i * 3.0) + i * 1.3 + seed * 12);
      final lx = fx + (i - 1.5) * sc * 0.46;
      final tipY = fy + up * sc * (1.4 + 2.0 * lf);
      final midY = (fy + tipY) / 2;
      final wob = math.sin(_t * 6.5 + i * 1.9) * sc * 0.3;
      canvas.drawPath(
        Path()
          ..moveTo(lx - sc * 0.42, fy)
          ..quadraticBezierTo(lx - sc * 0.24, midY, lx + wob, tipY)
          ..quadraticBezierTo(lx + sc * 0.24, midY, lx + sc * 0.42, fy)
          ..close(),
        Paint()
          ..shader = Gradient.linear(
            Offset(lx, fy),
            Offset(lx, tipY),
            [
              Color.fromRGBO(255, 214, 130, 0.62 * lf * envO),
              Color.fromRGBO(232, 104, 34, 0.34 * envO),
              const Color(0x00000000),
            ],
            const [0.0, 0.4, 1.0],
          ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dinamik katmanlar
  // ---------------------------------------------------------------------------

  /// Engelin altındaki kazılmış / bozulmuş toprak şeridi (zemin düzleminde).
  void _drawBarrierScar(
    Canvas canvas,
    BoardMetrics m,
    Barrier b, {
    bool ghost = false,
  }) {
    final (a, z) = m.barrierLine(b);
    final cell = m.cell;
    final w = cell * 0.34;

    canvas
      ..drawLine(
        a,
        z,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w
          ..color = ghost ? const Color(0x1F000000) : const Color(0x5E241C12),
      )
      ..drawLine(
        a,
        z,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 0.5
          ..color = ghost ? const Color(0x14000000) : const Color(0x8C160F0A),
      );

    if (ghost) return;

    // Dağılmış toprak (kenar boyunca kısa çentikler) — konumlar çapaya göre
    // bir kez üretilip önbelleğe alınır (kare başına RNG + Random ayırma yok).
    for (final (c, rr) in _flecksFor(b, a, z, w, cell)) {
      canvas.drawCircle(c, rr, _scarFleckP);
    }
  }

  List<(Offset, double)> _flecksFor(
    Barrier b,
    Offset a,
    Offset z,
    double w,
    double cell,
  ) {
    final key = b.toNotation();
    final cached = _scarFlecks[key];
    if (cached != null) return cached;
    final out = <(Offset, double)>[];
    final dir = z - a;
    final len = dir.distance;
    if (len >= 1) {
      final u = dir / len;
      final perp = Offset(-u.dy, u.dx);
      final rnd = math.Random(key.hashCode);
      final count = math.max(3, (len / (cell * 0.2)).round());
      for (var i = 0; i < count; i++) {
        final base = Offset.lerp(a, z, (i + 0.5) / count)!;
        final s = rnd.nextBool() ? 1.0 : -1.0;
        final off = perp * s * (w * 0.45 + rnd.nextDouble() * cell * 0.13);
        out.add((base + off, 1 + rnd.nextDouble() * 1.7));
      }
    }
    _scarFlecks[key] = out;
    return out;
  }

  /// Mayın: toprağa gömülü **alçak** zeytin disk (miğferden ayrışsın diye
  /// kasıtlı yassı) + basınç halkası + 3 tetik çubuğu + amber işaret. Billboard.
  void _drawMine(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Barrier b, {
    required bool preview,
    required bool ok,
  }) {
    final (a, z) = m.barrierLine(b);
    final mid = Offset.lerp(a, z, 0.5)!;
    final ms = _p(mid);
    final sc = proj.scaleAt(mid);
    final vRatio = (proj.verticalScaleAt(mid) / sc).clamp(0.3, 1.0);
    final r = m.cell * 0.22 * sc;

    final Color body;
    final Color ring;
    final Color plate;
    if (preview) {
      body = ok ? const Color(0xD94E7A51) : const Color(0xD9974440);
      ring = ok ? const Color(0xF03B6A43) : const Color(0xF07C332D);
      plate = ok ? const Color(0xF07EBC81) : const Color(0xF0DC776C);
    } else {
      body = const Color(0xFF57542F);
      ring = const Color(0xFF373420);
      plate = const Color(0xFF6B6743);
    }

    final cy = ms + Offset(0, _liftY(r * 0.16));
    final w = r * 2.0;
    final h = r * 0.9 * vRatio + r * 0.16;

    // Toprak yatağı — bake edilmiş ışık lekesi (kare başına `MaskFilter.blur`
    // yerine; birden çok mayın varken kasmayı önler).
    canvas
      ..save()
      ..translate(ms.dx, ms.dy)
      ..scale(1.0, (h * 1.35) / (w * 1.3));
    _glowBlob(canvas, Offset.zero, w * 0.65, const Color(0x66241B10));
    canvas.restore();

    canvas
      // Gövde yan yüzü (koyu, hafif "aşağı").
      ..drawOval(
        Rect.fromCenter(
            center: cy.translate(0, h * 0.16), width: w, height: h),
        Paint()..color = ring,
      )
      // Üst yüz.
      ..drawOval(Rect.fromCenter(center: cy, width: w, height: h),
          Paint()..color = body)
      // Basınç halkası.
      ..drawOval(
        Rect.fromCenter(center: cy, width: w * 0.62, height: h * 0.62),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09
          ..color = const Color(0x77201B10),
      )
      // Göbek.
      ..drawOval(
        Rect.fromCenter(center: cy, width: w * 0.34, height: h * 0.34),
        Paint()..color = plate,
      )
      // Üst-sol ışık.
      ..drawArc(
        Rect.fromCenter(center: cy, width: w, height: h),
        math.pi * 1.08,
        math.pi * 0.8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09
          ..color = const Color(0x33F3ECDC),
      );

    if (!preview) {
      // 3 tetik çubuğu — üst yüzden dışa + "yukarı".
      final prong = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.12
        ..color = const Color(0xFF706B4A);
      for (final ang in const [-1.15, -0.1, 1.0]) {
        final d = Offset(math.cos(ang - math.pi / 2), math.sin(ang - math.pi / 2));
        final root = cy + d * (r * 0.34);
        final tip = root + d * (r * 0.42) + Offset(0, _liftY(r * 0.55));
        canvas
          ..drawLine(root, tip, prong)
          ..drawCircle(tip, r * 0.08, Paint()..color = const Color(0xFF908B60));
      }
      // Amber tehlike işareti.
      canvas
        ..drawCircle(cy, r * 0.2, Paint()..color = const Color(0xFFCF9A2B))
        ..drawCircle(cy, r * 0.09, Paint()..color = const Color(0xFF171009));
    }
  }

  /// Dikenli tel: 3 eğik direk + tepeleri arası sarkan 3 tel + dikenler.
  /// Billboard.
  void _drawWire(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Barrier b, {
    bool preview = false,
    bool ok = true,
  }) {
    final (a, z) = m.barrierLine(b);
    final pivot = Offset.lerp(a, z, 0.5)!;
    final scMid = proj.scaleAt(pivot);

    final Color woodC;
    final Color wireC;
    if (preview) {
      woodC = ok ? const Color(0xDD3E6E44) : const Color(0xDD8A3E37);
      wireC = ok ? const Color(0xF085CE86) : const Color(0xF0E88079);
    } else {
      woodC = const Color(0xFF4A3D2C);
      wireC = const Color(0xFF6B6250);
    }

    // Zemin gölgesi.
    canvas.drawLine(
      _p(a),
      _p(z),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = m.cell * 0.1 * scMid
        ..color = const Color(0x3D000000),
    );

    // Direkler — "yukarı" yönü eğime göre değişir (diğer oyuncuya döner).
    final tops = <Offset>[];
    for (final pt in [a, pivot, z]) {
      final s = _p(pt);
      final sca = proj.scaleAt(pt);
      final h = m.cell * 0.52 * sca;
      final top = s + Offset(0, _liftY(h));
      tops.add(top);
      canvas
        ..drawOval(
          Rect.fromCenter(
              center: s, width: m.cell * 0.26 * sca, height: m.cell * 0.11 * sca),
          Paint()..color = const Color(0xFF291F15),
        )
        ..drawLine(
          s,
          top,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.cell * 0.062 * sca
            ..color = woodC,
        )
        ..drawLine(
          s.translate(-m.cell * 0.014 * sca, 0),
          top.translate(-m.cell * 0.014 * sca, 0),
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.cell * 0.022 * sca
            ..color = const Color(0x40F3ECDC),
        );
    }

    // Teller (bitişik direk tepeleri arası, sarkan). Boyalar bir kez ayarlanır
    // (kare başına ~90 `Paint()` ayırması kasmaya yol açıyordu).
    final strandP = _wireStrandP
      ..strokeWidth = 1.9 * scMid.clamp(0.7, 1.5)
      ..color = wireC;
    final barbP = _wireBarbP..color = wireC;
    for (var i = 0; i < tops.length - 1; i++) {
      final p0 = tops[i];
      final p1 = tops[i + 1];
      for (var k = 0; k < 3; k++) {
        final sag = m.cell * (0.05 + k * 0.045) * scMid;
        final c0 = p0.translate(0, _liftY(k * 1.6 * scMid));
        final c1 = p1.translate(0, _liftY(k * 1.6 * scMid));
        // Sarkma "aşağı" (ayakta yönün tersi).
        final ctrl = Offset.lerp(c0, c1, 0.5)! + Offset(0, -_liftY(sag));
        canvas.drawPath(
          Path()
            ..moveTo(c0.dx, c0.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, c1.dx, c1.dy),
          strandP,
        );
        final s = 3.0 * scMid.clamp(0.7, 1.5);
        for (var t = 0.14; t < 0.93; t += 0.2) {
          final bp = _quadPoint(c0, ctrl, c1, t);
          canvas
            ..drawLine(bp + Offset(-s, -s), bp + Offset(s, s), barbP)
            ..drawLine(bp + Offset(-s, s), bp + Offset(s, -s), barbP);
        }
      }
    }
  }

  static Offset _quadPoint(Offset p0, Offset c, Offset p1, double t) {
    final mt = 1 - t;
    return p0 * (mt * mt) + c * (2 * mt * t) + p1 * (t * t);
  }

  /// "Miğferli mevzi" askeri: kazılı toprak taban + siper (brim) + miğfer
  /// kubbesi. Billboard — "yukarı" yönü eğimle işaret değiştirir (diğer
  /// oyuncuya döner). Üst üste binmede net kalması için güçlü dış hat.
  void _drawSoldier(
    Canvas canvas,
    BoardMetrics m,
    BoardProjection proj,
    Square sq,
    _Faction fac,
  ) {
    final g = m.cellCenter(sq);
    final gs = _p(g);
    final sc = proj.scaleAt(g);
    final vRatio = (proj.verticalScaleAt(g) / sc).clamp(0.25, 1.0);
    final r = m.cell * 0.36 * sc;
    final rh = r * 0.92;

    // Işık/kabartma yönü işareti (eğimle döner).
    final us = _tilt >= 0 ? 1.0 : -1.0;
    final flip = us < 0 ? math.pi : 0.0;

    final brimC = Offset(gs.dx, gs.dy + _liftY(r * 0.5));
    final domeC = Offset(gs.dx, gs.dy + _liftY(r * 0.5 + rh * 0.58));

    // 1) Zemin gölgesi — bake edilmiş ışık lekesi (koyu), blur yok.
    canvas.save();
    canvas.translate(gs.dx, gs.dy);
    canvas.scale(1.0, vRatio * 0.5);
    _glowBlob(canvas, Offset.zero, r * 1.5, const Color(0x82000000));
    canvas.restore();

    // 2) Kazılı mevzi tabanı (yerde).
    final moundRect = Rect.fromCenter(
      center: gs,
      width: r * 2.35,
      height: r * 0.78 * vRatio + r * 0.3,
    );
    canvas
      ..drawOval(
        moundRect.inflate(r * 0.08),
        Paint()..color = const Color(0xFF221D15),
      )
      ..drawOval(moundRect, Paint()..color = const Color(0xFF4A3F2E))
      ..drawArc(
        moundRect,
        math.pi * 1.12 + flip,
        math.pi * 0.76,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08
          ..color = const Color(0x3AC9B48A),
      );

    // 3) Miğfer kubbesi.
    final domeRect = Rect.fromCircle(center: domeC, radius: rh);
    canvas
      // Koyu kontur halesi — arkadaki engelden ayrışması için.
      ..drawCircle(domeC, rh + math.max(1.6, r * 0.06),
          Paint()..color = const Color(0x8C0E0906))
      ..drawCircle(
        domeC,
        rh,
        Paint()
          ..shader = Gradient.radial(
            domeC + Offset(-rh * 0.36 * us, -rh * 0.42 * us),
            rh * 1.9,
            [fac.lit, fac.mid, fac.dark],
            const [0.0, 0.46, 1.0],
          ),
      )
      // Karşı kenar gövde gölgesi.
      ..drawArc(
        domeRect.deflate(rh * 0.04),
        -math.pi * 0.18 + flip,
        math.pi * 0.62,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rh * 0.5
          ..color = const Color(0x2E140D08),
      )
      // Kenar ışığı.
      ..drawArc(
        domeRect.deflate(rh * 0.06),
        math.pi * 1.16 + flip,
        math.pi * 0.42,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rh * 0.13
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x9EF3ECDC),
      );

    // 4) Siper (brim) — kubbenin alt kısmını örter.
    final brimRect = Rect.fromCenter(
      center: brimC,
      width: rh * 2.5,
      height: rh * 0.62 * vRatio + rh * 0.28,
    );
    canvas
      ..drawOval(brimRect.shift(Offset(0, -_liftY(r * 0.05))),
          Paint()..color = const Color(0x662A1C12))
      ..drawOval(brimRect, Paint()..color = fac.brim)
      ..drawArc(
        brimRect,
        math.pi * 1.1 + flip,
        math.pi * 0.75,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = const Color(0x66F3ECDC),
      );

    // 5) Görünen üst kubbe yayı boyunca güçlü dış hat.
    canvas.drawArc(
      domeRect,
      math.pi * 0.94 + (us < 0 ? math.pi : 0.0),
      math.pi * 1.12,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, r * 0.05)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x66100A05),
    );
  }
}

/// Havada süzülen tek bir kül/toz zerresi (ekran uzayı, normalize başlangıç).
class _Mote {
  const _Mote(
    this.nx,
    this.ny,
    this.r,
    this.spd,
    this.amp,
    this.phase,
    this.a,
    this.ember,
  );

  /// Normalize başlangıç konumu (0..1 viewport).
  final double nx;
  final double ny;

  /// Yarıçap (px), yukarı drift hızı (px/sn), yatay salınım genliği (px).
  final double r;
  final double spd;
  final double amp;
  final double phase;

  /// Alfa (çok düşük — ortam tozu).
  final double a;

  /// `true` ise soluk turuncu kor (titreşen), değilse gri kül.
  final bool ember;
}

/// Bir tarafın miğfer renk tonları (aynı form, farklı renk — [Faction] simetrik).
class _Faction {
  const _Faction(this.mid, this.lit, this.dark, this.brim);

  final Color mid;
  final Color lit;
  final Color dark;
  final Color brim;

  static const p1 = _Faction(
    Color(0xFF3E6E9E),
    Color(0xFF6796C2),
    Color(0xFF294C6E),
    Color(0xFF32587E),
  );
  static const p2 = _Faction(
    Color(0xFFA2433B),
    Color(0xFFC96A5E),
    Color(0xFF6F2C26),
    Color(0xFF83352D),
  );
}
