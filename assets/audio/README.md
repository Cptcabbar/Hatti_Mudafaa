# Ses varlıkları

`pubspec.yaml` `assets/audio/` ve `assets/audio/sfx/` dizinlerini tanır. Kod
dosyalara **`assets/`** öneki olmadan erişir (`AssetSource('audio/...')`).

## Arka plan müziği

`assets/audio/Before_the_Iron_Gates.mp3` — döngüde, ses %50, menü + oyun
boyunca. "Ayarlar → Müzik" duraklatır/sürdürür.

Parçayı değiştirmek: yeni mp3'ü buraya koy, `lib/audio/game_music.dart`
içindeki `_asset` sabitini güncelle.

- **Web:** tarayıcı ilk kullanıcı dokunuşundan önce ses çalmaz; menüde bir
  düğmeye basınca başlar (`GameMusic.nudge`).

## Efekt sesleri — `assets/audio/sfx/`

Tümü **sentetik** (kayıt yok), `tool/gen_sfx.mjs` ile üretilir:

```
node tool/gen_sfx.mjs
```

| Dosya | Ne zaman | Notlar |
|---|---|---|
| `step_dirt.wav` | piyon 1 kare ilerledi (7×7 / normal) | ~190 ms, alçak tok adım |
| `step_snow.wav` | piyon ilerledi (**Geniş Arazi** — karlı) | ~260 ms, çıtırtı + gıcırtı |
| `mine.wav` | mayın yerleştirildi | ~340 ms, toprağa bas + metal tık |
| `wire.wav` | dikenli tel çekildi | ~500 ms, gerilim twang + hışırtı |

"Ayarlar → Ses" anahtarına bağlı. Bağlantı: `lib/audio/game_sfx.dart`;
tetiklendiği yer `lib/game/board_component.dart` `_advanceAnimations`
(hamle/engel durumu bir önceki kareyle karşılaştırılır).

Sesi/karakteri beğenmezsen `tool/gen_sfx.mjs` içindeki parametreleri
(zarf `tau`, frekanslar, tane sayısı) değiştir, scripti tekrar çalıştır.

## ⚖️ Lisans

Müzik + üretilen SFX: yalnızca ticari + uygulamaya gömme izinli. SFX'ler
%100 özgün sentez (örnek/kütüphane sesi yok). Lisans kaydı ROADMAP Faz 5'te
`docs/legal-clearance.md`'ye eklenecek.
