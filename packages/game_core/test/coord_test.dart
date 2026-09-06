import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('Square', () {
    test('parse ve toString birbirinin tersi', () {
      for (final s in ['a1', 'd4', 'g7', 'c3']) {
        expect(Square.parse(s).toString(), s);
      }
    });

    test('parse doğru 0 tabanlı indeks üretir', () {
      expect(Square.parse('a1'), const Square(0, 0));
      expect(Square.parse('d1'), const Square(3, 0));
      expect(Square.parse('d7'), const Square(3, 6));
      expect(Square.parse('g7'), const Square(6, 6));
    });

    test('geçersiz notasyon FormatException atar', () {
      expect(() => Square.parse('1a'), throwsFormatException);
      expect(() => Square.parse(''), throwsFormatException);
      expect(() => Square.parse('a0'), throwsFormatException);
    });

    test('step ve komşuluk', () {
      expect(const Square(3, 3).step(Direction.north), const Square(3, 4));
      expect(const Square(3, 3).step(Direction.west), const Square(2, 3));
      expect(
        const Square(3, 3).isOrthogonalNeighbor(const Square(3, 4)),
        isTrue,
      );
      expect(
        const Square(3, 3).isOrthogonalNeighbor(const Square(4, 4)),
        isFalse,
      );
    });
  });

  group('Edge', () {
    test('kanonik: argüman sırası önemsiz', () {
      final a = Edge.between(const Square(2, 2), const Square(2, 3));
      final b = Edge.between(const Square(2, 3), const Square(2, 2));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('komşu olmayan kareler ArgumentError', () {
      expect(
        () => Edge.between(const Square(0, 0), const Square(2, 0)),
        throwsArgumentError,
      );
    });
  });
}
