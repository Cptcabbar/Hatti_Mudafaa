import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';

import 'board_metrics.dart';

/// Tahtaya dokunmanın ne anlama geldiği.
enum InteractionMode { move, mine, wire }

/// `game_core` durumu ile yerel oyun arayüzü arasındaki köprü.
///
/// Kural kararı vermez — yalnızca [Rules]'u çağırır, geçmişi (undo için) tutar
/// ve etkileşim durumunu (mod, engel önizlemesi) yönetir.
class GameController extends ChangeNotifier {
  GameController({GameConfig config = GameConfig.v1})
      : _config = config,
        _state = BoardState.initial(config);

  final GameConfig _config;
  BoardState _state;
  final List<BoardState> _history = [];
  InteractionMode _mode = InteractionMode.move;
  Barrier? _preview;

  BoardState get state => _state;
  InteractionMode get mode => _mode;
  Barrier? get preview => _preview;
  bool get canUndo => _history.isNotEmpty;
  bool get isOver => _state.isOver;
  Player get turn => _state.turn;

  int get currentArmory => _state.armoryOf(_state.turn);

  bool canAfford(BarrierType type) =>
      currentArmory >= _config.costOf(type == BarrierType.wire);

  /// move modunda sıradaki askerin gidebileceği kareler (vurgu için).
  Set<Square> get legalStepTargets =>
      Rules.pawnMoves(_state).map((m) => m.to).toSet();

  bool get canConfirmPreview {
    final p = _preview;
    if (p == null) return false;
    if (currentArmory < p.cost(_config)) return false;
    return Rules.canPlaceBarrier(_state, p);
  }

  void setMode(InteractionMode m) {
    if (_mode == m) return;
    _mode = m;
    _preview = null;
    notifyListeners();
  }

  /// Tahtaya dokunma. [local] = tahta-yerel piksel (0..side).
  void tapBoard(Offset local, BoardMetrics metrics) {
    if (_state.isOver) return;
    switch (_mode) {
      case InteractionMode.move:
        final sq = metrics.squareAt(local);
        if (sq != null && legalStepTargets.contains(sq)) {
          _apply(StepMove(sq));
        }
      case InteractionMode.mine:
      case InteractionMode.wire:
        final type = _mode == InteractionMode.mine
            ? BarrierType.mine
            : BarrierType.wire;
        var candidate = metrics.nearestBarrierSlot(local, type);
        if (!Rules.canPlaceBarrier(_state, candidate)) {
          final alt = _rotate(candidate);
          if (Rules.canPlaceBarrier(_state, alt)) candidate = alt;
        }
        _preview = candidate;
        notifyListeners();
    }
  }

  void rotatePreview() {
    final p = _preview;
    if (p == null) return;
    _preview = _rotate(p);
    notifyListeners();
  }

  /// Aynı çapada ters yönlü engel; çapa geçerli aralığa kırpılır.
  Barrier _rotate(Barrier b) {
    final n = _config.boardSize;
    final flipped = b.orientation == BarrierOrientation.horizontal
        ? BarrierOrientation.vertical
        : BarrierOrientation.horizontal;
    final maxCol =
        (b.isWire || flipped == BarrierOrientation.vertical) ? n - 2 : n - 1;
    final maxRow =
        (b.isWire || flipped == BarrierOrientation.horizontal) ? n - 2 : n - 1;
    return Barrier(
      type: b.type,
      orientation: flipped,
      anchor: Square(
        b.anchor.col.clamp(0, maxCol),
        b.anchor.row.clamp(0, maxRow),
      ),
    );
  }

  void confirmPreview() {
    if (!canConfirmPreview) return;
    _apply(PlaceBarrierMove(_preview!));
  }

  void cancelPreview() {
    if (_preview == null) return;
    _preview = null;
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;
    _state = _history.removeLast();
    _resetInteraction();
  }

  void restart() {
    _history.clear();
    _state = BoardState.initial(_config);
    _resetInteraction();
  }

  void _apply(Move move) {
    _history.add(_state);
    _state = Rules.applyMove(_state, move);
    _resetInteraction();
  }

  void _resetInteraction() {
    _preview = null;
    _mode = InteractionMode.move;
    notifyListeners();
  }
}
