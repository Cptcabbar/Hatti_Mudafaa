import 'dart:math';

import 'package:game_core/game_core.dart';

import 'ai_engine.dart';
import 'evaluation.dart';

/// `game_core` üstünde negamax + alpha-beta yapan yapay zeka.
///
/// Zorluk profilleri:
/// - **hard** — iteratif derinleşme (hedef derinlik 3), gürültüsüz, en iyi
///   hamle. Yarışta hata yapmaz.
/// - **medium** — derinlik 2 + değerlendirmeye küçük gürültü → makul ama
///   kusursuz olmayan "normal oyuncu".
/// - **easy** — 1-ply, ağır gürültü + engel isteksizliği: hedefine yürür ama
///   sık sık zayıf hamle yapar, engeli nadir kullanır.
///
/// Isolate içinde çalıştırılmak üzere tasarlandı (`chooseMove` saf hesap).
class NegamaxEngine implements AiEngine {
  NegamaxEngine(this.difficulty, {int? seed}) : _rng = Random(seed);

  final AiDifficulty difficulty;
  final Random _rng;

  @override
  Future<Move> chooseMove(
    BoardState state, {
    required Duration budget,
  }) async {
    final legal = Rules.legalMoves(state);
    if (legal.isEmpty) {
      throw StateError('Yasal hamle yok — oyun bitmiş olmalı');
    }
    if (legal.length == 1) return legal.first;

    return switch (difficulty) {
      AiDifficulty.easy => _easy(state, legal),
      AiDifficulty.medium =>
        _think(state, maxDepth: 2, noise: 4, budget: budget) ?? legal.first,
      AiDifficulty.hard =>
        _think(state, maxDepth: 3, noise: 0, budget: budget) ?? legal.first,
    };
  }

  /// Kolay: rakibi hiç modellemez (1-ply). Çoğunlukla kendi hedefine doğru en
  /// iyi adımı seçer ama %20 ihtimalle rastgele bir piyon hamlesi yapar
  /// (bilerek zayıf hamle) ve engelleri neredeyse hiç kullanmaz.
  Move _easy(BoardState state, List<Move> legal) {
    final me = state.turn;
    final pawn = legal.whereType<StepMove>().toList();
    if (pawn.isNotEmpty && _rng.nextDouble() < 0.20) {
      return pawn[_rng.nextInt(pawn.length)];
    }
    Move? best;
    var bestScore = double.negativeInfinity;
    for (final m in legal) {
      final child = Rules.applyMove(state, m, validate: false);
      var sc = Evaluation.score(child, me).toDouble();
      sc += (_rng.nextDouble() - 0.5) * 16;
      if (m is PlaceBarrierMove) sc -= 22; // engeli neredeyse hiç kullanma
      if (sc > bestScore) {
        bestScore = sc;
        best = m;
      }
    }
    return best!;
  }

  Move? _think(
    BoardState state, {
    required int maxDepth,
    required int noise,
    required Duration budget,
  }) {
    final deadline = DateTime.now().add(budget);
    Move? best;
    for (var d = 1; d <= maxDepth; d++) {
      final search = _Search(deadline, noise, _rng, previousBest: best);
      final result = search.runRoot(state, d);
      if (result != null) best = result;
      if (search.outOfBudget) break;
    }
    return best;
  }
}

/// Tek bir (sabit derinlikli) negamax araması. Süre / düğüm bütçesi dolunca
/// o ana dek bulunan en iyiyi döndürür.
class _Search {
  _Search(this._deadline, this._noise, this._rng, {this.previousBest});

  final DateTime _deadline;
  final int _noise;
  final Random _rng;

  /// Önceki derinliğin en iyi hamlesi — kökte önce denenir (kesilirse güvenli).
  final Move? previousBest;

  static const int _nodeCap = 120000;
  static const int _inf = Evaluation.win * 4;

  int _nodes = 0;
  bool _hitLimit = false;

  bool get outOfBudget => _hitLimit;

  bool _checkBudget() {
    if (_hitLimit) return true;
    if (_nodes >= _nodeCap || DateTime.now().isAfter(_deadline)) {
      _hitLimit = true;
    }
    return _hitLimit;
  }

  /// Kök: en iyi hamle (bütçe dolsa da ilk incelenen — en iyi sıralanan — hamle
  /// döner). Hiç hamle inceleyemezse `null`.
  Move? runRoot(BoardState root, int depth) {
    final moves = _ordered(root, depth);
    Move? best;
    var alpha = -_inf;
    for (final m in moves) {
      final child = Rules.applyMove(root, m, validate: false);
      final v = -_negamax(child, depth - 1, -_inf, -alpha);
      if (best == null || v > alpha) {
        alpha = v;
        best = m;
      }
      if (_checkBudget()) break;
    }
    return best;
  }

  int _negamax(BoardState s, int depth, int alpha, int beta) {
    _nodes++;
    if (s.isOver || depth <= 0 || _checkBudget()) {
      return _leaf(s);
    }
    var value = -_inf;
    for (final m in _ordered(s, depth)) {
      final child = Rules.applyMove(s, m, validate: false);
      final v = -_negamax(child, depth - 1, -beta, -alpha);
      if (v > value) value = v;
      if (value > alpha) alpha = value;
      if (alpha >= beta) break;
    }
    return value;
  }

  int _leaf(BoardState s) {
    var e = Evaluation.forSideToMove(s);
    if (_noise > 0 && !s.isOver) {
      e += _rng.nextInt(_noise * 2 + 1) - _noise;
    }
    return e;
  }

  /// Bu düğümün aday hamleleri, iyi-önce sıralı. Engeller yalnızca ağacın
  /// üst kısmında (kalan derinlik ≥ 2) ve rakip/kendi en kısa yoluna değenlerle
  /// sınırlı — dallanmayı ~150'den ~15'e indirir.
  List<Move> _ordered(BoardState s, int remainingDepth) {
    final moves = <Move>[...Rules.pawnMoves(s)];
    if (remainingDepth >= 2) {
      moves.addAll(_nearbyBarriers(s));
    }
    final keyed = [
      for (final m in moves)
        (m, -Evaluation.forSideToMove(Rules.applyMove(s, m, validate: false))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final ordered = [for (final k in keyed) k.$1];
    // PV hamlesini öne al.
    final pv = previousBest;
    if (pv != null) {
      final i = ordered.indexOf(pv);
      if (i > 0) {
        ordered
          ..removeAt(i)
          ..insert(0, pv);
      }
    }
    return ordered;
  }

  List<PlaceBarrierMove> _nearbyBarriers(BoardState s) {
    final hot = <Square>{};
    for (final p in Player.values) {
      final path = Pathfinding.shortestPathToRow(
        s,
        s.pawnOf(p),
        s.goalRowOf(p),
      );
      if (path != null) hot.addAll(path);
      hot.add(s.pawnOf(p));
    }
    return [
      for (final m in Rules.barrierMoves(s))
        if (m.barrier.blockedEdges().any(
              (e) => hot.contains(e.a) || hot.contains(e.b),
            ))
          m,
    ];
  }
}
