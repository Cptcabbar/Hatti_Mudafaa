import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings.dart';

/// Arka plan müziği — tek parça (`assets/audio/theme.mp3`), döngüde.
///
/// "Ayarlar → Müzik" anahtarına bağlıdır. Ses eklentisi yoksa (testler),
/// dosya yoksa ya da platform sesi engellerse **tamamen sessiz** kalır —
/// hiçbir istisna dışarı sızmaz, oyun akışı etkilenmez.
///
/// Web'de tarayıcılar ilk kullanıcı etkileşiminden önce ses çalmayı engeller;
/// bu yüzden [nudge] ana menüdeki ilk dokunuşta çağrılır.
class GameMusic {
  GameMusic._();
  static final GameMusic instance = GameMusic._();

  /// `assets/` öneki olmadan — audioplayers `AssetSource` bunu ekler.
  static const String _asset = 'audio/theme.mp3';

  AudioPlayer? _player;
  bool _initDone = false;
  bool _playing = false;

  /// Açılışta bir kez ([main]'de). Ses eklentisi yoksa çıkar; varsa anahtarı
  /// dinlemeye başlar ve müzik açıksa çalmayı dener.
  Future<void> init() async {
    if (_initDone) return;
    _initDone = true;
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(0.5);
      _player = p;
    } catch (e) {
      _player = null; // eklenti yok (test) / platformda ses yok
      if (kDebugMode) debugPrint('GameMusic devre dışı: $e');
      return;
    }
    AppSettings.instance.music.addListener(() => _apply());
    await _apply();
  }

  /// Kullanıcı jesti (menü dokunuşu) sonrası tekrar dene — web autoplay kilidi.
  void nudge() {
    if (_player != null &&
        AppSettings.instance.music.value &&
        !_playing) {
      _apply();
    }
  }

  Future<void> _apply() async {
    final p = _player;
    if (p == null) return;
    final on = AppSettings.instance.music.value;
    try {
      if (on) {
        if (_playing) {
          await p.resume();
        } else {
          await p.play(AssetSource(_asset), volume: 0.5);
          _playing = true;
        }
      } else if (_playing) {
        await p.pause();
      }
    } catch (e) {
      // Dosya yok / autoplay engeli — sessiz geç, sonra tekrar denenebilir.
      _playing = false;
      if (kDebugMode) debugPrint('GameMusic: $e');
    }
  }
}
