import 'package:flutter_test/flutter_test.dart';
import 'package:hatti_mudafaa/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('load() diskteki değerleri okur; değişiklik kaydedilir', () async {
    SharedPreferences.setMockInitialValues({'particles': false, 'timed': false});

    final s = AppSettings.instance;
    await s.load();

    expect(s.particles.value, isFalse);
    expect(s.timed.value, isFalse);
    // varsayılanlar (diskte yok) korunur
    expect(s.sound.value, isTrue);

    s.particles.value = true;
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('particles'), isTrue);
  });
}
