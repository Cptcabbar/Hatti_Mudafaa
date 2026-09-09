# Platform derleme (Android + iOS)

Uygulama kodu tamamen taşınabilir (Flutter + Flame, saf-Dart `game_core` /
`game_ai`; hiç `dart:io` / `dart:html` yok). Bu doküman native derleme, imzalama
ve marka varlıklarının nasıl üretildiğini anlatır.

> **Bu geliştirme makinesi:** Android SDK yok, Mac yok. Native derlemeler
> **CI** üzerinden yapılır/doğrulanır (`.github/workflows/ci.yml`):
> - `analyze-and-test` — her push/PR: `dart analyze` + 3 test seti.
> - `build-android` — her push (Linux, ucuz): `flutter build apk` **ve**
>   `flutter build appbundle` → `hatti-mudafaa-android` artifact'ı (APK + AAB,
>   90 gün). Her push'ta güncel bir paket hazır bekler.
> - `build-ios` — **yalnızca elle tetik** (macOS runner 10x dakika çarpanı):
>   `flutter build ios --release --no-codesign` → imzasız IPA
>   (`hatti-mudafaa-ios-unsigned`, 90 gün).

## Android paketi çekme (APK / AAB)

1. GitHub → **Actions** → en son yeşil `CI` çalışması → `build-android` job'ı.
2. Sayfanın altındaki **Artifacts → `hatti-mudafaa-android`** indir (zip; içinde
   `app-release.apk` + `app-release.aab`).
3. **APK** → test cihazına gönder → aç → "bilinmeyen kaynaklara izin ver" → kur.
   `android/app/debug.keystore` ile imzalı (sabit test anahtarı) — her CI
   derlemesi aynı imza, yani yeni sürümü **kaldırmadan** güncellersin.
   Play Store anahtarı **değildir**.
4. **AAB** → Play Console'a yüklenir (Play App Signing yeniden imzalar).

## iOS paketi çekme (imzasız IPA)

1. GitHub → **Actions** → sol menüde **CI** → sağ üstte **Run workflow** →
   dalı `main` seç → **Run workflow**. (macOS runner ~15 dk.)
2. Çalışma bitince → `build-ios` job'ı → **Artifacts → `hatti-mudafaa-ios-unsigned`**.
3. Bu IPA **imzasızdır** — doğrudan iPhone'a kurulmaz. Seçenekler:
   - **Sideloadly** / **AltStore** (ücretsiz): kendi Apple ID'nle yeniden
     imzalar, 7 günde bir yenilemek gerekir. Hızlı test için yeterli.
   - **Mac + Apple Developer hesabı** ($99/yıl): Xcode'da imzalı `.ipa` +
     TestFlight / App Store (aşağıya bak).
4. Kod/pbxproj kırılması burada da doğrulanır (native derleme gerçekten geçti mi).

> **Not:** `audioplayers` eklentisi (ses hattı) native Android + iOS kodu taşır.
> CI derlemesi bunu kapsar; ilk iOS derlemesinde `pod install` adımına dikkat.

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

### Derleme — CI'da elle tetik (bu projede Mac yok)

Actions → **CI** → **Run workflow** → `build-ios` job'ı
`flutter build ios --release --no-codesign` çalıştırıp imzasız IPA'yı artifact
yapar (yukarı bak). `project.pbxproj` / privacy manifest / storyboard / native
eklenti (`audioplayers`) kırılması burada yakalanır.

**Mac erişilince** (App Store'a / imzalı kuruluma):

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
