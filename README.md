# Kapalı Yol

Sıra tabanlı strateji oyunu — mayınlı bir savaş alanında askerini karşı kenara
ulaştır. Quoridor mekaniğinden esinlenen, kendi temasına ve kurallarına sahip
özgün bir yapım. Android + iOS (Flutter + Flame).

> **İsim geçicidir** — nihai isim marka taramasıyla belirlenecek (`docs/legal-clearance.md`).

## Durum

Faz 0 (temeller). İlerleme: [ROADMAP.md](ROADMAP.md).

## Yapı

| Yol | İçerik |
|---|---|
| `lib/` | Flutter uygulaması — `game/` (Flame), `ui/`, `online/`, `ads/`, `theme/` |
| `packages/game_core/` | Saf Dart kural motoru. Tek doğruluk kaynağı: `docs/rules.md` |
| `packages/game_ai/` | Yapay zeka rakip (Faz 2) |
| `docs/rules.md` | Oyun kuralları spesifikasyonu (canonical) |
| `docs/legal-clearance.md` | Telif/marka uyum kayıt defteri |

## Geliştirme

```sh
flutter pub get
dart pub get -C packages/game_core
dart pub get -C packages/game_ai

dart analyze                       # kök + lib/ + test/
dart analyze packages/game_core
dart analyze packages/game_ai

(cd packages/game_core && dart test)
(cd packages/game_ai && dart test)
flutter test

flutter run
```

> Not: bu makinede `flutter analyze` sarmalayıcısı ortam kaynaklı çöküyor
> (`FormatException`); `dart analyze` aynı `analysis_options.yaml`'ı kullanır ve
> sorunsuz çalışır. CI `dart analyze` kullanır.

## Lisans / telif notu

Oyun mekaniği ve kuralları telif hakkıyla korunmaz; bu proje "Quoridor" ismini,
görsellerini veya kural metnini kullanmaz. Ayrıntı: `docs/legal-clearance.md`.
