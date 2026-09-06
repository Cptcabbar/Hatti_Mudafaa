# Kapalı Yol — Yol Haritası & İlerleme Takibi

> Proje kod adı: **Kapalı Yol** (geçici — nihai isim Faz 0'da marka taramasıyla belirlenecek).
> Her adım tamamlandıkça kutucuklar (`[ ]` → `[x]`) buradan işaretlenir.
> **⚖️ işaretli maddeler yasal uyum (telif/marka) gereğidir — atlanamaz, kanıtı `docs/legal-clearance.md`'ye kaydedilir.**

## Context (neden bu plan)

Quoridor mekaniğinden esinlenen, **kendi temasına (asker / savaş alanı), ismine ve görselliğine sahip** sıra tabanlı strateji oyunu.

- Tek kod tabanı ile **Android + iOS** → **Flutter + Flame**.
- İki arkadaş **oda kodu** ile online → **Supabase** (realtime).
- Ekran altında **AdMob banner** + "reklamsız" IAP ile gelir.
- Kademeli yayın: **yerel (aynı cihaz) → yapay zeka rakibi (kolay/orta/zor) → online**.

Kilitlenen kararlar: Flutter+Flame · Supabase · Quoridor-türevi mekanik + tamamen özgün askeri sunum · kademeli MVP.

---

## Yasal uyum ilkeleri (projenin tüm süreci boyunca geçerli)

**Hukuki zemin (kaynaklar aşağıda):**
- **Oyun mekaniği ve kuralları telif hakkıyla korunmaz.** "Piyonu karşı sıraya götür, arasına engel koyarak rakibin yolunu uzat, yolu tamamen kapatma" sistemini kullanmak serbesttir. Mahkemeler (ABD dâhil) mekaniklerin/sistemlerin telif dışı olduğunu defalarca teyit etti.
- **Korunan şeyler (bunlardan kesin uzak durulacak):**
  1. **Kural kitapçığının metni** — Gigamic'in yazdığı cümleler, örnekler, diyagram anlatımları.
  2. **Görsel/grafik varlıklar** — tahta görünümü, renk paleti, piyon ve duvar biçimi, kutu tasarımı, ikonografi, font seçimi (trade dress dâhil).
  3. **"Quoridor" ismi ve türevleri** — Gigamic'in ticari markası. İsim, alt başlık, mağaza meta verisi, ASO anahtar kelimesi, reklam metni, ekran görüntüsü yazısı — hiçbirinde geçmeyecek. "Quor-", "koridor/corridor" kelime oyunu dâhil karıştırma ihtimali olan hiçbir şey.
- **Patent:** Quoridor 1997'de yayımlandı; olası patentler süresi doldu → patent kısıtı yok (yine de Faz 0'da 10 dk doğrulama).
- **Karşılaştırmalı pazarlama yasak:** "Quoridor klonu / benzeri / alternatifi" gibi ifadeler marka ihlali + haksız rekabet riski. Oyun yalnızca kendi teması üzerinden tanıtılır.

**Bu proje için ayrışma stratejisi (her biri bilinçli tasarım kararı):**

| Orijinal (Quoridor) | Bu proje |
|---|---|
| İsim: "Quoridor" | Tamamen özgün, marka-taraması yapılmış isim |
| 9×9 tahta | **7×7 tahta** |
| Tek tip 2 birimlik "duvar" | İki tip engel: **1 birimlik mayın** + **2 birimlik dikenli tel** |
| Soyut ahşap estetik, Gigamic paleti | Askeri / savaş alanı teması, özgün sanat, farklı palet |
| Gigamic kural kitapçığı metni | Sıfırdan kendi cümlelerimizle yazılmış kural spec'i |

> Not: Bu bir hukuki mütalaa değildir. Ticari yayın öncesi (özellikle isim/marka için) bir fikri mülkiyet avukatından kısa bir ön inceleme almak önerilir — "Yayın öncesi yasal kontrol kapısı" bölümüne bakınız.

---

## Açık kararlar (Faz 0'da netleştir)

- [x] Tahta boyutu **7×7** onaylandı (playtest'e göre `GameConfig`'ten ayarlanabilir)
- [x] Engel ekonomisi: **8 puanlık cephanelik**, mayın 1 / dikenli tel 2 puan, ayrı dağıtım yok
- [x] Engel kuralları: çakışma yasak · tel+tel dik kesişme yasak · mayın serbest kesişir (bkz. `docs/rules.md` §5.3)
- [x] Çapraz atlama: **koşullu** (yalnızca düz atlama kapalıyken)
- [ ] Online MVP'de tur zaman sınırı (Faz 4)
- [ ] Hedef yaş: **12+/Teen** mi (kişiselleştirilmiş reklam serbest) yoksa herkese açık (AdMob Families kuralları)

---

## FAZ 0 — Temeller + yasal zemin

- [x] **⚖️ `docs/legal-clearance.md` oluşturuldu** — kayıt defteri şablonu hazır; tablolar tamamlandıkça doldurulacak
- [x] **⚖️ `docs/rules.md` sıfırdan, kendi cümlelerimizle yazıldı** — v1 kesinleşti (bağımsız yazım, kendi terminolojimiz, 7×7, iki tip engel, `GameConfig`)
- [ ] **⚖️ Oyun ismi belirlendi** — "Quoridor" ve türevleri (Quor-, koridor/corridor) kesinlikle dışında; askeri temayı destekleyen özgün isim
- [ ] **⚖️ İsim marka taraması yapıldı** — TÜRKPATENT, EUIPO eSearch, USPTO TESS, WIPO Global Brand Database + Google Play / App Store isim araması + genel web; Nice sınıfları **9 (yazılım)** ve **28 (oyunlar)**; sonuç ekran görüntüleriyle `legal-clearance.md`'ye
- [ ] **⚖️ (Önerilir) Marka başvurusu değerlendirildi** — seçilen isim için sınıf 9 + 28; en azından "başvurulacak" kararı ve bütçesi netleşti
- [ ] **⚖️ Alan adı + sosyal medya + geliştirici hesap adları** özgün isimle rezerve edildi
- [ ] Flutter projesi + `packages/game_core` + `packages/game_ai` (saf Dart) iskeleti kuruldu
- [ ] CI kuruldu (`flutter analyze` + `flutter test`), lint kuralları
- [ ] Klasör iskeleti (`lib/game`, `lib/ui`, `lib/online`, `lib/ads`, `lib/theme`)
- [ ] **⚖️ Tema bible taslağı** — askeri/savaş alanı; renk paleti, piyon (asker), engel görselleri, arka plan; **Gigamic'in görsel dili referans alınmadı**, moodboard'da Quoridor görseli yok; tüm ilham kaynakları serbest lisanslı
- [ ] **⚖️ Görsel varlık kaynak politikası belirlendi** — yalnızca özgün çizim / CC0 / satın alınmış asset lisansı / yazılı sipariş sözleşmesi; her varlığın kaydı tutulacak
- [ ] **⚖️ Font lisansları kontrol edildi** — ticari + uygulamaya gömülü kullanım izinli (SIL OFL / Apache / satın alma); kayıt `legal-clearance.md`'ye
- [ ] Hedef yaş derecelendirmesi kararı verildi (reklam kurallarını belirler)
- [ ] **⚖️ Türkçe + İngilizce yerelleştirme** altyapısı (`intl` / ARB); string'lerde "Quoridor" yasağı lint/gözden geçirme kuralı

---

## FAZ 1 — Yerel hot-seat MVP (oynanabilir)

### Kural motoru (`game_core`)
- [ ] Board state modeli (7×7 grid, piyon konumları, engeller, sıra, kalan mayın/tel)
- [ ] Piyon hareket üretimi (ortogonal 1 adım)
- [ ] Zıplama + çapraz atlama kuralları (kendi spec'imize göre)
- [ ] Engel yerleştirme geçerliliği (sınır, çakışma, kesişme)
- [ ] **"Yol kapatılamaz" kontrolü** — her engel için iki oyuncuya da BFS/DFS ile hedefe yol
- [ ] Kazanma tespiti
- [ ] Seri hale getirme: kompakt hamle notasyonu + tam state (JSON)
- [ ] **⚖️ Kod terminolojisi kendi jargonumuzla** (değişken/sınıf isimleri kural spec'imizden; orijinal oyunun özel terimleri kullanılmadı)
- [ ] Unit test seti: kural + "yol kapatma" invaryantı + zıplama + kazanma + serialization round-trip
- [ ] Property-based test: rastgele oyunlar illegal state'e düşmüyor

### Flame oyun ekranı
- [ ] Tahta / grid render
- [ ] **⚖️ İki asker piyon** — özgün tasarım, gerçek ordu amblemi/logosu/kişi benzerliği yok
- [ ] **⚖️ Mayın (1-seg) görseli + yerleştirme UI** — özgün varlık
- [ ] **⚖️ Dikenli tel (2-seg) görseli + yerleştirme UI** — özgün varlık
- [ ] Tur göstergesi + kalan mayın/tel sayacı
- [ ] Hamle animasyonları
- [ ] Kazanma ekranı + yeniden başlat

### Uygulama kabuğu
- [ ] Ana menü (Yerel oyna / Ayarlar)
- [ ] Ayarlar (dil, ses)
- [ ] **⚖️ Tek tema** — tüm varlıkları özgün/lisanslı, kayıtları `legal-clearance.md`'de
- [ ] Geri alma (undo) — onaylı
- [ ] **Çıkış kriteri:** iki kişi aynı cihazda kurallara uygun tam oyun oynuyor; `game_core` testlerle tam kapsanmış; tüm görsel varlıkların lisans/özgünlük kaydı tam

---

## FAZ 2 — Yapay zeka rakibi

- [ ] **⚖️ AI sıfırdan yazıldı** — negamax + alpha-beta + BFS değerlendirme (genel algoritmalar, IP sorunu yok); hazır bir Quoridor AI kodu **kopyalanmadı** (kopyalanırsa lisansına — MIT/GPL — uyulur ve kayıt tutulur)
- [ ] Değerlendirme: BFS en kısa yol farkı + kalan engel + konum
- [ ] Zaman bütçeli iterative deepening
- [ ] AI hesaplaması **isolate** içinde
- [ ] **Kolay** (sığ derinlik + blunder + engelleri nadiren kullanır)
- [ ] **Orta** (makul derinlik + iyi engel kullanımı)
- [ ] **Zor** (tam derinlik + optimuma yakın)
- [ ] Menüde "Yapay zekaya karşı" + zorluk seçimi
- [ ] "Düşünüyor" göstergesi + AI hamle animasyonu
- [ ] Test: AI hiç illegal hamle yapmıyor; zor > orta > kolay tutarlı; hamle < ~1–2 sn (orta telefon)
- [ ] **Çıkış kriteri:** üç seviye oynanabilir, zorluk farkı hissediliyor

---

## FAZ 3 — Para kazanma + mağazaya hazır

- [ ] `google_mobile_ads` entegrasyonu
- [ ] Alt adaptive banner — layout'ta rezerve yuva, tahtayı örtmüyor
- [ ] Google UMP consent akışı (EEA)
- [ ] iOS ATT izni + Info.plist (`GADApplicationIdentifier`, `SKAdNetwork`, ATT metni)
- [ ] Test unit ID → gerçek AdMob unit ID geçişi (yayın öncesi)
- [ ] Maçlar arası interstitial (maç ortası/açılış **değil**)
- [ ] Rewarded video: "ipucu" / "geri alma"
- [ ] "Reklamsız" IAP (`in_app_purchase`, non-consumable)
- [ ] Analitik (Firebase Analytics / PostHog): maç tamamlama, oturum, reklam gösterimi, D1 retention
- [ ] Crash reporting (Crashlytics / Sentry)
- [ ] Remote config (AI ayarı, reklam sıklığı, feature flag)
- [ ] **⚖️ Gizlilik politikası** sayfası + URL (KVKK + GDPR: reklam ID, Supabase oturumu, analitik)
- [ ] Play Data Safety formu / App Store privacy labels
- [ ] **⚖️ Uygulama ikonu + ekran görüntüleri + tanıtım videosu** — yalnızca özgün görsellerimiz
- [ ] **⚖️ Mağaza metinleri** (başlık, açıklama, ASO anahtar kelimeleri, promosyon metni, ekran görüntüsü yazıları) — "Quoridor" ve karşılaştırmalı ifade **içermiyor**; otomatik kontrol/gözden geçirme yapıldı
- [ ] **⚖️ Üçüncü parti bağımlılık lisansları** derlendi — uygulama içi "Lisanslar" ekranı / `NOTICE` dosyası
- [ ] IARC yaş anketi (silah/şiddet teması dürüst)
- [ ] **⚖️ "Yayın öncesi yasal kontrol kapısı" (aşağıda) tamamlandı**
- [ ] Play internal/closed testing kanalına yükleme
- [ ] Düşük donanımlı Android cihazda elle test
- [ ] **Çıkış kriteri:** test kanalında inceleme geçiyor; reklam consent ile çıkıyor; IAP sandbox'ta çalışıyor; yasal kapı kapalı

---

## FAZ 4 — Online (iki arkadaş)

- [ ] Supabase projesi + `matches` / `moves` şeması + RLS
- [ ] Anonymous auth (+ sonra e-posta/Google/Apple hesap bağlama)
- [ ] Oda kodu üretme/çözme fonksiyonu (Edge Function / Postgres)
- [ ] `lib/online/`: `supabase_client`, `match_repository`, `realtime_sync`
- [ ] Realtime abonelik ile hamle senkronizasyonu
- [ ] Tur zorlaması + hamle doğrulama (güven modeli `docs/rules.md`'de)
- [ ] Lobi: oda oluştur → kod/link paylaş
- [ ] Kodla odaya katıl + hazır ol
- [ ] Yeniden bağlanma / oyuna devam
- [ ] Rakip çıkışı / terk yönetimi
- [ ] Opsiyonel tur sayacı
- [ ] Rövanş akışı
- [ ] **⚖️ Paylaşım linki / davet metni** üçüncü parti marka kullanmıyor
- [ ] Test: farklı ağlarda iki cihaz tam oyun; zorla kopma + yeniden bağlanma; iki oyuncu da çıkınca
- [ ] **Çıkış kriteri:** iki cihaz baştan sona sorunsuz online oyun

---

## FAZ 5 — Cila & lansman

- [ ] Tema motoru (art / palet / sfx config ile değişir)
- [ ] **⚖️ En az 2. tema** — her tema için görsel varlık lisans/özgünlük kaydı; gerçek ordu amblemleri, logoları, insan benzerlikleri **kullanılmadı** (marka + kişilik hakları); jenerik estetik
- [ ] **⚖️ Ses efektleri + müzik** — royalty-free + ticari + uygulamaya gömme izinli lisans; kayıtları `legal-clearance.md`'ye
- [ ] Haptik geri bildirim
- [ ] İnteraktif öğretici / onboarding
- [ ] İstatistik / profil ekranı
- [ ] Online için basit ELO / sıralama
- [ ] Düşük donanım performans geçişi (60 fps)
- [ ] Soft launch (tek pazar) → retention + reklam geliri izleme
- [ ] İterasyon → global yayın (Android, sonra iOS)

---

## Yayın öncesi yasal kontrol kapısı (mağazaya göndermeden önce hepsi `[x]` olmalı)

- [ ] İsim + logo marka taraması temiz; sonuçlar `legal-clearance.md`'de arşivli
- [ ] (Karar verildiyse) Marka başvurusu yapıldı — sınıf 9 + 28
- [ ] Kural metni bağımsız yazıldı — Quoridor kitapçığından türetilmediği doğrulandı
- [ ] Tahta + mekanik orijinalden ayrışıyor (7×7, iki tip engel, farklı engel sayısı)
- [ ] Tüm görsel varlıklar: özgün veya lisans belgesi dosyada (piyon, engeller, arka plan, ikon, temalar)
- [ ] Tüm font / ses / müzik: ticari + gömülü lisans belgesi dosyada
- [ ] Mağaza listesi (tüm diller) "Quoridor" ve karşılaştırmalı ifade içermiyor — otomatik tarama geçti
- [ ] Ekran görüntüleri / tanıtım videosu yalnızca özgün içerik
- [ ] Üçüncü parti kod bağımlılık lisansları uyumlu; attribution/NOTICE eklendi
- [ ] Gizlilik politikası yayında; KVKK + GDPR veri işleme envanteri dokümante
- [ ] (Ticari ciddi yayın) IP avukatı ön incelemesi yapıldı — en azından isim/marka için

---

## Oluşturulacak yapı / kritik dosyalar
- `packages/game_core/` — `board.dart`, `move.dart`, `rules.dart`, `pathfinding.dart`, `game_state.dart`, `notation.dart`, `test/`
- `packages/game_ai/` — `search.dart`, `evaluation.dart`, isolate wrapper
- `lib/game/` — Flame: `board_component.dart`, `pawn_component.dart`, `barrier_component.dart`, `game_scene.dart`, input handler'lar
- `lib/ui/` — menüler, lobi, ayarlar, paywall
- `lib/online/` — `supabase_client.dart`, `match_repository.dart`, `realtime_sync.dart`
- `lib/ads/` — `ad_manager.dart`, consent (UMP/ATT)
- `lib/theme/` — tema config'leri
- `supabase/migrations/`, `supabase/functions/`
- `docs/rules.md` — canonical kural spec'i (bağımsız yazılmış)
- `docs/legal-clearance.md` — marka aramaları, asset lisansları, kararlar arşivi
- `ROADMAP.md` — bu dosya (ilerleme takibi)

---

## Doğrulama (nasıl test edilir)
- CI'da `flutter test` (game_core + ai + widget/golden) ve `flutter analyze` yeşil.
- Elle: tam yerel oyun; her AI seviyesi; farklı ağlarda iki cihazla online oyun + zorla kopma testi.
- AdMob: test reklamları rezerve yuvada tahtayı örtmeden çıkıyor; UMP formu EEA'da beliriyor; IAP sandbox'ta reklamı kaldırıyor.
- Yasal: "Yayın öncesi yasal kontrol kapısı" tüm maddeleri `[x]`; `docs/legal-clearance.md` eksiksiz.
- Yayın öncesi: Play internal testing build kuruluyor, privacy/Data Safety tamam, politika uyarısı yok.

---

## Kaynaklar
- [Quoridor — Wikipedia](https://en.wikipedia.org/wiki/Quoridor)
- [Not Playing Around: Board Games and Intellectual Property Law — American Bar Association](https://www.americanbar.org/groups/intellectual_property_law/resources/landslide/archive/not-playing-around-board-games-intellectual-property-law/)
- [The Board Game Designer's Guide to US Intellectual Property Law — Meeple Mountain](https://www.meeplemountain.com/articles/the-board-game-designers-guide-to-intellectual-property-law/)
- [Are Board Games Copyrighted? What's Protected (2026) — Legal Moves Law Firm](https://legalmoveslawfirm.com/board-games-copyrighted/)
