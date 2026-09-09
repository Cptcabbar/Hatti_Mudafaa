# Hattı Müdafaa

Mayınlı bir savaş alanında askerini karşı kenara ulaştırmaya çalıştığın, sıra tabanlı bir strateji oyunu. Quoridor'un "rakibinin yolunu engelle" fikrinden ilham aldım, ama kendi temam, kendi kurallarım ve kendi görsel dilimle baştan kurdum. Android ve iOS için Flutter + Flame ile geliştiriliyor.

İsim henüz kesinleşmedi: Türkiye mağazasında "Hattı Müdafaa" olarak gidiyor, uluslararası pazar için Latin harfli / İngilizce bir isim üzerinde çalışıyorum ve marka taraması hâlâ sürüyor (detaylar `docs/legal-clearance.md`'de).

## Nerede durduğu

Şu an Faz 2'deyiz: aynı cihazda iki kişilik yerel oyun tamam, yapay zeka rakibi de üç zorluk seviyesiyle oynanabilir durumda. Sırada reklam/mağaza hazırlığı, ardından online mod var. Güncel ilerleme: `ROADMAP.md`.

## Proje yapısı

| Yol | İçerik |
|---|---|
| `lib/` | Flutter uygulaması — `game/` (Flame), `ui/`, `online/`, `ads/`, `theme/` |
| `packages/game_core/` | Saf Dart kural motoru. Kuralların tek doğruluk kaynağı: `docs/rules.md` |
| `packages/game_ai/` | Yapay zeka rakibi |
| `docs/rules.md` | Oyun kuralları spesifikasyonu |
| `docs/theme-bible.md` | Görsel/işitsel yön (jenerik askeri tema, low-poly) |
| `docs/legal-clearance.md` | Telif/marka uyum kayıt defteri |
| `docs/platform-build.md` | Android/iOS derleme, imzalama, ikon+splash üretimi |

Hedef platformlar Android ve iOS. `android/` ve `ios/` klasörleri buna göre yapılandırıldı (portre kilidi, koyu açılış ekranı, özgün ikon, imza iskeleti); native derlemeler CI üzerinden doğrulanıyor. `web/` klasörü şu an sadece geliştirme sırasında tarayıcıda önizleme yapmak için (`flutter run -d chrome`) — ayrı bir yayın hedefi olarak henüz planlanmıyor. Detaylar: `docs/platform-build.md`.

## Geliştirmeye başlamak

```
flutter pub get
dart pub get -C packages/game_core
dart pub get -C packages/game_ai
```

Analiz ve testler:

```
dart analyze
dart analyze packages/game_core
dart analyze packages/game_ai

(cd packages/game_core && dart test)
(cd packages/game_ai && dart test)
flutter test
```

Çalıştırmak için:

```
flutter run
```

(CI `dart analyze` kullanıyor; `flutter analyze` bazı ortamlarda sorun çıkarabiliyor, `dart analyze` aynı `analysis_options.yaml`'ı kullanıp sorunsuz çalışıyor.)

## Lisans / telif notu

Oyunun mekaniği ve kuralları telif hakkıyla korunmaz; bu proje "Quoridor" adını, görsellerini ya da kural metnini kullanmıyor — kurallar sıfırdan yazıldı. Detaylar: `docs/legal-clearance.md`.
