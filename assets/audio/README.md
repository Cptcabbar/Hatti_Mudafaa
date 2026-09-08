# Ses varlıkları

Oyunun sesleri buraya konur. `pubspec.yaml` bu klasörü bir varlık dizini
olarak tanır; kod dosyalara **`assets/`** öneki olmadan erişir
(`AssetSource('audio/<dosya>')`).

## Arka plan müziği

Ana müzik parçasını şu adla buraya koy:

```
assets/audio/theme.mp3
```

- Biçim: **mp3** (web + Android + iOS'ta en sorunsuz). `.ogg` / `.wav` da
  çalışır ama o zaman `lib/audio/game_music.dart` içindeki dosya adını
  güncelle.
- Döngüde çalar; sesi kod içinde 0.5'e ayarlı. Ana menü / oyun boyunca sürer.
- "Ayarlar → Müzik" anahtarı bu parçayı duraklatır / sürdürür.
- **Web'de tarayıcı politikası:** ses ilk kullanıcı dokunuşundan önce başlamaz;
  menüde bir düğmeye basınca devreye girer (kod bunu hallediyor).
- **⚖️ Lisans:** yalnızca ticari + uygulamaya gömme izinli müzik (royalty-free /
  satın alınmış / kendi bestən). Lisans kaydını `docs/legal-clearance.md`'ye
  ekle (ROADMAP Faz 5).

## Efekt sesleri (sonra)

`assets/audio/sfx/` altına eklenecek; "Ayarlar → Ses" anahtarına bağlanacak.
Henüz bağlanmadı.
