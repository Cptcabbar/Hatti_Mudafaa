import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:game_ai/game_ai.dart';
import 'package:game_core/game_core.dart';

import 'board_metrics.dart';

/// Tahtaya dokunmanın ne anlama geldiği.
enum InteractionMode { move, mine, wire }

/// `game_core` durumu ile yerel oyun arayüzü arasındaki köprü.
///
/// Kural kararı vermez — yalnızca [Rules]'u çağırır, geçmişi (undo için) tutar,
/// etkileşim durumunu (mod, engel önizlemesi) ve tur sayacını yönetir.
class GameController extends ChangeNotifier {
  GameController({
    GameConfig config = GameConfig.v1,
    this.timed = true,
    this.turnDuration = const Duration(seconds: 30),
    this.aiDifficulty,
    this.aiPlayer = Player.p2,
    int? aiSeed,
  })  : _config = config,
        _state = BoardState.initial(config),
        _engine = aiDifficulty == null
            ? null
            : NegamaxEngine(aiDifficulty, seed: aiSeed) {
    _startTurnTimer();
    _maybeStartAiTurn();
  }

  final GameConfig _config;

  /// Süreli mod açık mı (her tur [turnDuration]).
  final bool timed;
  final Duration turnDuration;

  /// Doluysa oyun yapay zekaya karşı; [aiPlayer] hamlelerini AI yapar.
  final AiDifficulty? aiDifficulty;

  /// Yapay zekanın oynadığı taraf (varsayılan: Kırmızı / P2).
  final Player aiPlayer;

  final AiEngine? _engine;
  final Random _rng = Random();

  /// AI şu an hamlesini hesaplıyor / "düşünüyor" (3-5 sn'lik pencere dâhil).
  bool _aiThinking = false;

  /// `dispose` sonrası geç dönen AI görevini yutmak için.
  bool _disposed = false;

  /// Her durum değişiminde artar — bekleyen AI görevi araya undo/restart
  /// girdiğini bundan anlar (BoardState kimlik/eşitlik taşımıyor).
  int _gen = 0;

  BoardState _state;
  final List<BoardState> _history = [];
  InteractionMode _mode = InteractionMode.move;
  Barrier? _preview;

  Timer? _ticker;
  double _secondsLeft = 0;

  BoardState get state => _state;
  InteractionMode get mode => _mode;
  Barrier? get preview => _preview;
  bool get canUndo => _history.isNotEmpty && !_aiThinking;
  bool get isOver => _state.isOver;
  Player get turn => _state.turn;

  /// Oyun yapay zekaya karşı mı.
  bool get vsAi => aiDifficulty != null;

  /// Yapay zeka bu an hamlesini düşünüyor — arayüz göstergeyi buna göre açar.
  bool get aiThinking => _aiThinking;

  /// Sıra yapay zekada mı (oyun sürüyorken).
  bool get isAiTurn =>
      vsAi && !_state.isOver && _state.turn == aiPlayer;

  /// İnsan oyuncu şu an tahtaya müdahale edebilir mi (AI turu / düşünme kilidi).
  bool get acceptsInput => !_state.isOver && !_aiThinking && !isAiTurn;

  /// Kalan tur süresi (saniye). Süreli mod kapalıysa 0.
  double get secondsLeft => _secondsLeft;

  /// Kalan sürenin oranı 0..1 (sayaç çubuğu için).
  double get turnFraction {
    final total = turnDuration.inMilliseconds / 1000.0;
    if (!timed || total <= 0) return 0;
    return (_secondsLeft / total).clamp(0.0, 1.0);
  }

  int armoryOf(Player p) => _state.armoryOf(p);
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
    if (!acceptsInput || _mode == m) return;
    _mode = m;
    _preview = null;
    notifyListeners();
  }

  /// Tahtaya dokunma. [local] = tahta-yerel piksel (0..side).
  void tapBoard(Offset local, BoardMetrics metrics) {
    if (!acceptsInput) return;
    switch (_mode) {
      case InteractionMode.move:
        final sq = metrics.squareAt(local);
        if (sq != null && legalStepTargets.contains(sq)) {
          _apply(StepMove(sq), validated: true);
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
    if (!acceptsInput || p == null) return;
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
    if (!acceptsInput) return;
    if (!canConfirmPreview) return; // §5.3 dört koşulu burada zaten doğrulandı
    _apply(PlaceBarrierMove(_preview!), validated: true);
  }

  void cancelPreview() {
    if (_preview == null) return;
    _preview = null;
    notifyListeners();
  }

  void undo() {
    if (_aiThinking || _history.isEmpty) return;
    _gen++;
    _state = _history.removeLast();
    // Yapay zekaya karşı: bir "geri al" hem AI'nın hem senin son hamleni alır —
    // yoksa sıra tekrar AI'ya döner ve aynı hamleyi yapardı.
    if (vsAi && _state.turn == aiPlayer && _history.isNotEmpty) {
      _state = _history.removeLast();
    }
    _resetInteraction();
  }

  void restart() {
    _gen++;
    _history.clear();
    _state = BoardState.initial(_config);
    _resetInteraction();
  }

  /// [validated] `true` ise hamlenin yasallığı çağrı öncesi kontrol edildi
  /// ([legalStepTargets] / [canConfirmPreview]) — [Rules.applyMove]'un tekrar
  /// doğrulaması atlanır. Doğrulama tüm engel adaylarını BFS'le tarar (kare
  /// başına yüzlerce yol araması + geçici nesne); bu, hamleden hemen sonra
  /// başlayan kamera dönüşünde çöp toplama takılmasına yol açıyordu.
  void _apply(Move move, {bool validated = false}) {
    _gen++;
    _history.add(_state);
    _state = Rules.applyMove(_state, move, validate: !validated);
    _resetInteraction();
  }

  void _resetInteraction() {
    _preview = null;
    _mode = InteractionMode.move;
    _startTurnTimer();
    notifyListeners();
    _maybeStartAiTurn();
  }

  // --- Yapay zeka turu -------------------------------------------------------

  /// Sıra AI'ya geçtiyse "düşünüyor" durumuna al ve hamleyi zamanla.
  void _maybeStartAiTurn() {
    if (_disposed || _aiThinking || !isAiTurn) return;
    _aiThinking = true;
    _ticker?.cancel(); // AI turunda sayaç işlemez
    _secondsLeft = 0;
    notifyListeners();
    unawaited(_runAiTurn());
  }

  /// AI hamlesini hesaplar, ardından toplam ~3-5 sn dolana kadar bekler ve
  /// oynar. Bu pencere insan rakibin de düşünmesi içindir (`docs/rules.md` §6:
  /// AI modunda tur süresi yoktur). Hesap web'de ana thread'i kısa süre
  /// (~150 ms) bloklar — isolate'e taşıma ROADMAP Faz 2'de.
  Future<void> _runAiTurn() async {
    final gen = _gen;
    final snapshot = _state;
    final think = Duration(milliseconds: 3000 + _rng.nextInt(2001)); // 3.0–5.0 sn
    final sw = Stopwatch()..start();

    // Göstergenin bir kare çizilmesine izin ver, sonra hesapla.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    Move move;
    try {
      move = await _engine!
          .chooseMove(snapshot, budget: const Duration(milliseconds: 500));
    } catch (_) {
      move = _autoMove(); // güvenlik ağı: hedefe en çok yaklaştıran adım
    }

    final rest = think - sw.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);

    if (_disposed || _gen != gen) return; // undo / restart / dispose araya girdi
    _aiThinking = false;
    _apply(move, validated: true);
  }

  // --- Tur sayacı --------------------------------------------------------------

  void _startTurnTimer() {
    _ticker?.cancel();
    if (!timed || _state.isOver) {
      _secondsLeft = 0;
      return;
    }
    _secondsLeft = turnDuration.inMilliseconds / 1000.0;
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _secondsLeft -= 0.2;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        _ticker?.cancel();
        _handleTimeout();
      }
      notifyListeners();
    });
  }

  /// Süre dolunca: sıradaki asker hedefe en çok yaklaşan adımı otomatik yapar.
  void _handleTimeout() {
    if (_state.isOver) return;
    _apply(_autoMove(), validated: true); // _autoMove yalnızca yasal hamle üretir
  }

  Move _autoMove() {
    final goalRow = _state.goalRowOf(_state.turn);
    final steps = Rules.pawnMoves(_state);
    if (steps.isEmpty) return Rules.legalMoves(_state).first;
    var best = steps.first;
    var bestDist = 1 << 30;
    for (final m in steps) {
      final d = Pathfinding.shortestDistanceToRow(_state, m.to, goalRow) ??
          (1 << 30);
      if (d < bestDist) {
        bestDist = d;
        best = m;
      }
    }
    return best;
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
