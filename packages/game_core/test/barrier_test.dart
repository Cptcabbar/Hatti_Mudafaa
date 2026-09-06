import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

Barrier _b(String notation) => Barrier.parse(notation);

void main() {
  group('Barrier.blockedEdges — docs/rules.md §5.2 örnekleri', () {
    test('Mc3h → yalnız c3↔c4', () {
      expect(_b('Mc3h').blockedEdges(), [
        Edge.between(Square.parse('c3'), Square.parse('c4')),
      ]);
    });

    test('Mc3v → yalnız c3↔d3', () {
      expect(_b('Mc3v').blockedEdges(), [
        Edge.between(Square.parse('c3'), Square.parse('d3')),
      ]);
    });

    test('Wc3h → c3↔c4 ve d3↔d4', () {
      expect(_b('Wc3h').blockedEdges(), containsAll([
        Edge.between(Square.parse('c3'), Square.parse('c4')),
        Edge.between(Square.parse('d3'), Square.parse('d4')),
      ]));
      expect(_b('Wc3h').blockedEdges(), hasLength(2));
    });

    test('Wc3v → c3↔d3 ve c4↔d4', () {
      expect(_b('Wc3v').blockedEdges(), containsAll([
        Edge.between(Square.parse('c3'), Square.parse('d3')),
        Edge.between(Square.parse('c4'), Square.parse('d4')),
      ]));
      expect(_b('Wc3v').blockedEdges(), hasLength(2));
    });
  });

  group('Barrier notasyon', () {
    test('parse ve toNotation birbirinin tersi', () {
      for (final n in ['Mc3h', 'Mf1v', 'Wc3h', 'Wa6v', 'Wg7h']) {
        expect(_b(n).toNotation(), n);
      }
    });

    test('geçersiz notasyon FormatException', () {
      expect(() => Barrier.parse('Xc3h'), throwsFormatException);
      expect(() => Barrier.parse('Wc3'), throwsFormatException);
      expect(() => Barrier.parse('Wc3x'), throwsFormatException);
    });

    test('pivot yalnız dikenli tel için dolu', () {
      expect(_b('Wc3h').pivot, Square.parse('c3'));
      expect(_b('Mc3h').pivot, isNull);
    });

    test('maliyet config üzerinden', () {
      const config = GameConfig.v1;
      expect(_b('Mc3h').cost(config), 1);
      expect(_b('Wc3h').cost(config), 2);
    });
  });
}
