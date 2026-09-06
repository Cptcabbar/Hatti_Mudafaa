/// Tahtadaki bir kare. `col` ve `row` **0 tabanlıdır** (`a1` = `Square(0, 0)`).
///
/// Notasyon: sütun `a..` harfleri, satır `1..` sayıları. Bkz. `docs/rules.md` §2.
class Square {
  const Square(this.col, this.row);

  final int col;
  final int row;

  static final RegExp _pattern = RegExp(r'^([a-z])([1-9][0-9]*)$');

  /// `"d1"` gibi bir notasyonu çözer. Geçersizse [FormatException] atar.
  factory Square.parse(String s) {
    final match = _pattern.firstMatch(s.trim().toLowerCase());
    if (match == null) {
      throw FormatException('Geçersiz kare notasyonu: "$s"');
    }
    final col = match.group(1)!.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = int.parse(match.group(2)!) - 1;
    return Square(col, row);
  }

  /// Verilen [dir] yönünde komşu kare (sınır kontrolü yapılmaz).
  Square step(Direction dir) => Square(col + dir.dc, row + dir.dr);

  /// İki kare arasındaki Manhattan uzaklığı.
  int manhattanTo(Square other) =>
      (col - other.col).abs() + (row - other.row).abs();

  /// Ortogonal komşu mu (tam bir adım)?
  bool isOrthogonalNeighbor(Square other) => manhattanTo(other) == 1;

  @override
  bool operator ==(Object other) =>
      other is Square && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() {
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    return '$colChar${row + 1}';
  }
}

/// Ortogonal hareket yönü.
enum Direction {
  north(0, 1),
  south(0, -1),
  east(1, 0),
  west(-1, 0);

  const Direction(this.dc, this.dr);

  final int dc;
  final int dr;

  Direction get opposite => switch (this) {
        Direction.north => Direction.south,
        Direction.south => Direction.north,
        Direction.east => Direction.west,
        Direction.west => Direction.east,
      };

  /// Bu yöne dik iki yön (çapraz atlama için).
  List<Direction> get perpendiculars => switch (this) {
        Direction.north || Direction.south => const [
            Direction.east,
            Direction.west,
          ],
        Direction.east || Direction.west => const [
            Direction.north,
            Direction.south,
          ],
      };
}

/// İki ortogonal komşu kare arasındaki sınır (kenar). Bir engel segmenti
/// tam olarak bir [Edge]'i kapatır.
///
/// Kanonik biçim: `a`, `b`'den satır-öncelikli sırada küçüktür; böylece
/// `Edge(x, y)` ve `Edge(y, x)` eşittir.
class Edge {
  Edge._(this.a, this.b);

  final Square a;
  final Square b;

  /// İki komşu kare arasındaki kenar. Kareler komşu değilse [ArgumentError].
  factory Edge.between(Square s1, Square s2) {
    if (!s1.isOrthogonalNeighbor(s2)) {
      throw ArgumentError('Kareler komşu değil: $s1, $s2');
    }
    final ordered = _order(s1, s2);
    return Edge._(ordered.$1, ordered.$2);
  }

  static (Square, Square) _order(Square s1, Square s2) {
    final key1 = s1.row * 1000 + s1.col;
    final key2 = s2.row * 1000 + s2.col;
    return key1 <= key2 ? (s1, s2) : (s2, s1);
  }

  @override
  bool operator ==(Object other) =>
      other is Edge && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => 'Edge($a|$b)';
}
