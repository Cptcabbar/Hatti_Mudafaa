import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings.dart';

/// Kısa oyun efekt sesleri — adım, mayın, dikenli tel. `assets/audio/sfx/*.wav`
/// (saf sentez; bkz. `tool/gen_sfx.mjs`).
///
/// "Ayarlar → Ses" anahtarına bağlıdır. Ses eklentisi / dosya yoksa **tamamen
/// sessiz** kalır — hiçbir istisna dışarı sızmaz.
class GameSfx {
  GameSfx._();
  static final GameSfx instance = GameSfx._();

  static const _stepDirt = 'audio/sfx/step_dirt.wav';
  static const _stepSnow = 'audio/sfx/step_snow.wav';
  static const _mine = 'audio/sfx/mine.wav';
  static const _wire = 'audio/sfx/wire.wav';

  /// Kısa örtüşmeler için küçük çalar havuzu (round-robin) — bir efektin
  /// kuyruğu bitmeden diğeri gelirse kesilmesin.
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ok = false;
  bool _initDone = false;

  Future<void> init() async {
    if (_initDone) return;
    _initDone = true;
    try {
      for (var i = 0; i < 3; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
      // Baytları önden getir ki ilk çalışta gecikme olmasın.
      await AudioCache.instance
          .loadAll([_stepDirt, _stepSnow, _mine, _wire]);
      _ok = true;
    } catch (e) {
      _ok = false;
      if (kDebugMode) debugPrint('GameSfx devre dışı: $e');
    }
  }

  /// Piyon bir kare ilerledi. [snow] ise karda yürüme sesi.
  void step({required bool snow}) =>
      _play(snow ? _stepSnow : _stepDirt, 0.75);

  /// Engel yerleştirildi.
  void barrier({required bool isWire}) =>
      _play(isWire ? _wire : _mine, isWire ? 0.6 : 0.8);

  void _play(String asset, double volume) {
    if (!_ok || !AppSettings.instance.sound.value) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // Ateşle-unut; hata olursa yut (dosya yok / platform).
    p.play(AssetSource(asset), volume: volume).catchError((Object _) {});
  }
}
