# Platform derleme (Android + iOS)

Uygulama kodu tamamen taşınabilir (Flutter + Flame, saf-Dart `game_core` /
`game_ai`; hiç `dart:io` / `dart:html` yok). Bu doküman native derleme, imzalama
ve marka varlıklarının nasıl üretildiğini anlatır.

> **Bu geliştirme makinesi:** Android SDK yok, Mac yok. Native derlemeler
> **CI** üzerinden yapılır/doğrulanır (`.github/workflows/ci.yml`):
> - `build-android` — her push/PR, `flutter build apk --release` (Linux);
>   çıktı APK'sı **artifact** olarak yüklenir.
> - `build-ios` — yalnız `main`'e push + elle tetik, `flutter build ios
>   --release --no-codesign` (macOS runner).

## Test APK'sı (yan yükleme)

1. GitHub → **Actions** → en son `CI` çalışması → `build-android` job'ı.
2. Sayfanın altındaki **Artifacts → `hatti-mudafaa-apk`** indir (zip; içinde
   `app-release.apk`).
3. APK'yı test cihazına gönder (mesaj / drive / kablo) → aç → "bilinmeyen
   kaynaklara izin ver" → kur.
4. APK `android/app/debug.keystore` ile imzalıdır (sabit test anahtarı) —
   her CI derlemesi aynı imza, yani yeni sürümü **kaldırmadan** güncelleyebilirsin.
   Bu Play Store anahtarı **değildir**.

---

## Marka varlıkları (ikon + açılış görseli)

Tek kaynak: [`lib/ui/brand_mark.dart`](../lib/ui/brand_mark.dart) (`BrandMark`
painter). PNG'ler ondan üretilir:

```sh
flutter test test/tool/generate_brand_assets.dart   # assets/brand/*.png + web/icons/*
dart run flutter_launcher_icons                      # Android mipmap + iOS AppIcon
dart run flutter_native_splash:create                # Android + iOS açılış ekranı
```

- `test/tool/*` `@Tags(['tool'])` taşır — normal test değildir, CI atlar
  (`flutter test --exclude-tags tool`).
- Konfigürasyon `pubspec.yaml` içinde (`flutter_launcher_icons:` /
  `flutter_native_splash:` blokları).
- Üretilen dosyalar (mipmap PNG'leri, `AppIcon.appiconset`, `drawable*/splash*`,
  `values-v31/styles.xml`, `LaunchScreen.storyboard` …) **commit'lenir**.
- İkonu değiştirmek: `BrandMark`'ı düzenle → üç komutu tekrar çalıştır.
- `values-v31` / `values-night-v31` içindeki `NormalTheme` `windowBackground`'ı
  `@color/launch_background` (koyu) olarak tutulur — `flutter_native_splash`
  bunu sistem temasına bağlar, elle geri alınır (bkz. `docs/theme-bible.md`).

---

## Android

### Sürüm

`pubspec.yaml` `version: 1.0.0+1` → `versionName` `1.0.0`, `versionCode` `1`.
Her yükleme öncesi `+build` numarasını artır.

### Yapılandırma

| Ayar | Değer | Yer |
|---|---|---|
| applicationId | `com.hattimudafaa.hatti_mudafaa` | `android/app/build.gradle.kts` |
| minSdk | 24 (Android 7.0) | aynı |
| targetSdk / compileSdk | `flutter.*` (SDK ile güncellenir) | aynı |
| Yön | `portrait` | `AndroidManifest.xml` |

### İmzalama

| Durum | Anahtar |
|---|---|
| `key.properties` **yok** | `android/app/debug.keystore` — repoda, şifre herkese açık `android`. Test/CI APK'ları hep aynı imza. |
| `key.properties` **var** | Oradaki mağaza yükleme anahtarı (gitignore'da). |

`debug.keystore` bilerek commit'li — amacı test cihazlarında sürüm güncellemenin
sorunsuz olması. **Play Store'a bununla çıkılmaz.** Mağaza anahtarı üretimi:

```sh
keytool -genkey -v -keystore ~/hatti-mudafaa-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

cp android/key.properties.example android/key.properties
# key.properties'i doldur (şifreler + storeFile yolu)
```

`key.properties` ve `*.jks` **git'e girmez** (`android/.gitignore`). Anahtarı
güvenli yedekle. Play Store'da **Play App Signing** önerilir — yükleme anahtarını
kaybetsen bile Google kurtarabilir.

### Yerel derleme (Android SDK olan makinede)

```sh
flutter build appbundle --release     # Play Store (.aab)
flutter build apk --release           # yan yükleme / test
```

---

## iOS

### Yapılandırma

| Ayar | Değer | Yer |
|---|---|---|
| Bundle ID | `com.hattimudafaa.hattiMudafaa` | `project.pbxproj` |
| Deployment target | iOS 15.0 | aynı |
| Yön | yalnız portre (iPad: portre + baş aşağı portre) | `Info.plist` |
| `ITSAppUsesNonExemptEncryption` | `false` | `Info.plist` |
| Privacy manifest | `Runner/PrivacyInfo.xcprivacy` (izleme yok, veri yok) | Runner hedefi (Resources) |

### Derleme — yalnız CI (bu projede Mac yok)

`build-ios` job'ı `flutter build ios --release --no-codesign` çalıştırır;
`project.pbxproj` / privacy manifest / storyboard değişikliklerini burada
doğrula.

**Mac erişilince** (App Store'a yükleme için gerekir):

```sh
cd ios && pod install && cd ..
open ios/Runner.xcworkspace          # Signing & Capabilities → Team seç
flutter build ipa --release          # App Store Connect'e Transporter ile yüklenir
```

App Store metinleri, gizlilik etiketleri, ATT ve reklam izinleri **Faz 3**
kapsamındadır — bkz. `ROADMAP.md`.

---

## Web (dev önizleme + playtest dağıtımı)

`flutter build web --release` → `build/web/`. Hosting notları (itch.io `<base
href>` yaması, `bsdtar` zip, `*.symbols` temizliği) bellekte / `ROADMAP.md`
"Playtest / dağıtım".

### Service worker önbelleği

Flutter web varsayılan olarak bir **service worker** kaydeder ve tüm uygulamayı
tarayıcı önbelleğine alır. Bu, prod (itch.io / kendi site) için iyidir —
çevrimdışı çalışır, yeni sürüm birkaç yüklemede otomatik güncellenir. Ama
**yerel geliştirme önizlemesinde** eski sürümü inatla servis eder (`?t=` ve
`Cache-Control: no-store` bile SW cache'ini geçmez).

- **Yerel önizleme:** `flutter build web --release --pwa-strategy=none` (SW
  kaydı üretilmez) + `no-store` gönderen bir statik sunucu.
- **Takılan SW'yi temizleme:** DevTools → Application → Service Workers →
  Unregister; ya da gizli sekme.
- **Prod build:** düz `flutter build web --release` (SW açık kalsın).

### Ses varlıkları

`assets/audio/` — müzik (`Before_the_Iron_Gates.mp3`) + `sfx/*.wav` (sentetik,
`tool/gen_sfx.mjs`). `pubspec.yaml` her iki dizini ayrı listeler (Flutter
varlık dizinleri özyinelemeli değil). Web'de ses ilk kullanıcı dokunuşundan
sonra başlar (tarayıcı autoplay politikası). Bkz. `assets/audio/README.md`.
