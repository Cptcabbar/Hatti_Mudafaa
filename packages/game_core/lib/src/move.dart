import 'barrier.dart';
import 'coord.dart';

/// Bir turda yapılan eylem. `docs/rules.md` §3.
///
/// İki tür: [StepMove] (askeri ilerlet) ve [PlaceBarrierMove] (engel koy).
sealed class Move {
  const Move();

  /// Notasyon dizesi (`docs/rules.md` §7).
  String toNotation();

  /// `"d2"` → [StepMove], `"Wc3h"` → [PlaceBarrierMove].
  factory Move.parse(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Boş hamle notasyonu');
    }
    final first = trimmed[0];
    if (first == 'M' || first == 'W') {
      return PlaceBarrierMove(Barrier.parse(trimmed));
    }
    return StepMove(Square.parse(trimmed));
  }
}

/// Sıradaki askeri [to] karesine götürür. Atlama da hedef kareyle yazılır;
/// ara adım kural motoru tarafından ima edilir.
class StepMove extends Move {
  const StepMove(this.to);

  final Square to;

  @override
  String toNotation() => to.toString();

  @override
  bool operator ==(Object other) => other is StepMove && other.to == to;

  @override
  int get hashCode => to.hashCode;

  @override
  String toString() => 'StepMove($to)';
}

/// Sıradaki oyuncunun cephaneliğinden [barrier]'ı sahaya yerleştirir.
class PlaceBarrierMove extends Move {
  const PlaceBarrierMove(this.barrier);

  final Barrier barrier;

  @override
  String toNotation() => barrier.toNotation();

  @override
  bool operator ==(Object other) =>
      other is PlaceBarrierMove && other.barrier == barrier;

  @override
  int get hashCode => barrier.hashCode;

  @override
  String toString() => 'PlaceBarrierMove($barrier)';
}
