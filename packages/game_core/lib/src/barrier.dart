import 'config.dart';
import 'coord.dart';

/// Engel tipi. `docs/rules.md` §5.1.
enum BarrierType {
  /// 1 kenar kapatır, 1 puan. Ayrık nesne — dik engellerle serbestçe kesişir.
  mine,

  /// Bir pivotta birleşen 2 ardışık kenar kapatır, 2 puan.
  wire,
}

/// Engelin fiziksel yönü.
///
/// - [horizontal]: engel yatay uzanır, **dikey (kuzey–güney) geçişi** kapatır.
/// - [vertical]: engel dikey uzanır, **yatay (doğu–batı) geçişi** kapatır.
enum BarrierOrientation { horizontal, vertical }

/// Tahtaya yerleştirilmiş bir engel.
///
/// [anchor], engelin sol-alt referans karesidir:
/// - mayın için: kapatılan kenarın alt/sol karesi,
/// - dikenli tel için: pivot karesi (kenar aralığı a–f × 1–6).
class Barrier {
  const Barrier({
    required this.type,
    required this.orientation,
    required this.anchor,
  });

  final BarrierType type;
  final BarrierOrientation orientation;
  final Square anchor;

  bool get isWire => type == BarrierType.wire;
  bool get isMine => type == BarrierType.mine;

  /// Cephanelik maliyeti (config'e göre).
  int cost(GameConfig config) => config.costOf(isWire);

  /// Dikenli teller için pivot karesi; mayınlar için `null`.
  ///
  /// İki dikenli tel aynı pivotta **farklı yönle** kesişemez (rules §5.3/3).
  Square? get pivot => isWire ? anchor : null;

  /// Bu engelin kapattığı kenarlar.
  ///
  /// Notasyon örnekleri (`docs/rules.md` §5.2):
  /// - `Mc3h` → `c3↔c4`
  /// - `Mc3v` → `c3↔d3`
  /// - `Wc3h` → `c3↔c4` ve `d3↔d4`
  /// - `Wc3v` → `c3↔d3` ve `c4↔d4`
  List<Edge> blockedEdges() {
    final c = anchor.col;
    final r = anchor.row;
    switch (orientation) {
      case BarrierOrientation.horizontal:
        // Dikey (kuzey) geçişi kapatır.
        final first = Edge.between(Square(c, r), Square(c, r + 1));
        if (isMine) return [first];
        return [
          first,
          Edge.between(Square(c + 1, r), Square(c + 1, r + 1)),
        ];
      case BarrierOrientation.vertical:
        // Yatay (doğu) geçişi kapatır.
        final first = Edge.between(Square(c, r), Square(c + 1, r));
        if (isMine) return [first];
        return [
          first,
          Edge.between(Square(c, r + 1), Square(c + 1, r + 1)),
        ];
    }
  }

  /// Notasyon dizesi — `Mc3h`, `Wa6v` gibi.
  String toNotation() {
    final prefix = isWire ? 'W' : 'M';
    final suffix = orientation == BarrierOrientation.horizontal ? 'h' : 'v';
    return '$prefix$anchor$suffix';
  }

  static final RegExp _pattern = RegExp(r'^([MW])([a-z][1-9][0-9]*)([hv])$');

  /// `"Wc3h"` gibi bir notasyonu çözer.
  factory Barrier.parse(String s) {
    final match = _pattern.firstMatch(s.trim());
    if (match == null) {
      throw FormatException('Geçersiz engel notasyonu: "$s"');
    }
    return Barrier(
      type: match.group(1) == 'W' ? BarrierType.wire : BarrierType.mine,
      anchor: Square.parse(match.group(2)!),
      orientation: match.group(3) == 'h'
          ? BarrierOrientation.horizontal
          : BarrierOrientation.vertical,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Barrier &&
      other.type == type &&
      other.orientation == orientation &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(type, orientation, anchor);

  @override
  String toString() => toNotation();
}
