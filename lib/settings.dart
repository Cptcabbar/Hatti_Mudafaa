import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda kalıcı kullanıcı ayarları. Tek örnek ([instance]); açılış
/// hazırlığında ([load]) diskten okunur, her değişiklikte kaydedilir.
///
/// - [timed] : süreli mod (her tur 30 sn)
/// - [sound] : efekt sesleri (ses hattı sonraki fazda bağlanacak)
/// - [music] : arka plan müziği (sonraki fazda)
/// - [particles] : ateş / duman / kül gibi hareketli çevre efektleri
class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  final ValueNotifier<bool> timed = ValueNotifier(true);
  final ValueNotifier<bool> sound = ValueNotifier(true);
  final ValueNotifier<bool> music = ValueNotifier(true);
  final ValueNotifier<bool> particles = ValueNotifier(true);

  SharedPreferences? _prefs;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      timed.value = p.getBool('timed') ?? timed.value;
      sound.value = p.getBool('sound') ?? sound.value;
      music.value = p.getBool('music') ?? music.value;
      particles.value = p.getBool('particles') ?? particles.value;
    } catch (_) {
      // Disk okunamazsa varsayılanlarla devam.
    }
    timed.addListener(() => _save('timed', timed.value));
    sound.addListener(() => _save('sound', sound.value));
    music.addListener(() => _save('music', music.value));
    particles.addListener(() => _save('particles', particles.value));
  }

  void _save(String key, bool value) {
    _prefs?.setBool(key, value);
  }
}
