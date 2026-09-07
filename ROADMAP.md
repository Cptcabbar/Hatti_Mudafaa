# Hattı Müdafaa — Yol Haritası & İlerleme Takibi

> Oyun ismi: **Hattı Müdafaa** (2026-09-06 belirlendi; marka taraması hâlâ Faz 0'da yapılacak).
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
- [x] Hedef yaş: **12+ / Teen** — hafif tematik şiddet, kan/ölüm yok; kişiselleştirilmiş reklam serbest
- [x] Tema: **jenerik askeri** (gerçek savaş/ordu/ülke temsili yok) · görsel stil **low-poly render → 2B** · uluslararası ad **TR + İngilizce başlık**

---

## FAZ 0 — Temeller + yasal zemin

- [x] **⚖️ `docs/legal-clearance.md` oluşturuldu** — kayıt defteri şablonu hazır; tablolar tamamlandıkça doldurulacak
- [x] **⚖️ `docs/rules.md` sıfırdan, kendi cümlelerimizle yazıldı** — v1 kesinleşti (bağımsız yazım, kendi terminolojimiz, 7×7, iki tip engel, `GameConfig`)
- [x] **⚖️ Oyun ismi belirlendi** — **"Hattı Müdafaa"** (askeri tema; "Quoridor" ile hiçbir bağı yok). Uluslararası pazar için Latin/İngilizce ad kararı ve marka taraması ayrı maddelerde.
- [ ] **⚖️ İngilizce başlık seçildi** — TR mağazada "Hattı Müdafaa", uluslararası mağazalarda İngilizce ad (aday: Trench Line / Hold the Line / No Man's Land / Frontline). Marka taramasına dahil.
- [ ] **⚖️ İsim marka taraması yapıldı** — "Hattı Müdafaa" + seçilen İngilizce başlık; TÜRKPATENT, EUIPO eSearch, USPTO TESS, WIPO Global Brand Database + Google Play / App Store isim araması + genel web; Nice sınıfları **9 (yazılım)** ve **28 (oyunlar)**; sonuç ekran görüntüleriyle `legal-clearance.md`'ye
- [ ] **⚖️ (Önerilir) Marka başvurusu değerlendirildi** — seçilen isim için sınıf 9 + 28; en azından "başvurulacak" kararı ve bütçesi netleşti
- [ ] **⚖️ Alan adı + sosyal medya + geliştirici hesap adları** özgün isimle rezerve edildi
- [x] Flutter projesi + `packages/game_core` + `packages/game_ai` (saf Dart) iskeleti kuruldu — `game_core`'da GameConfig/Square/Edge/Barrier/Move/BoardState + 23 test geçiyor
- [x] CI kuruldu (`.github/workflows/ci.yml` — `dart analyze` + `dart test` + `flutter test`), strict lint kuralları
- [x] Klasör iskeleti (`lib/game`, `lib/ui`, `lib/online`, `lib/ads`, `lib/theme`) — her biri README'li
- [x] Git deposu başlatıldı, ilk commit (`main` dalı)
- [x] **⚖️ Tema bible taslağı** — `docs/theme-bible.md`: jenerik askeri (gerçek savaş/ordu/ülke temsili yok), low-poly render → 2B, palet + öğeler + üretim hattı; **Gigamic'in görsel dili referans alınmadı**
- [ ] **⚖️ Görsel varlık kaynak politikası belirlendi** — yalnızca özgün çizim / CC0 / satın alınmış asset lisansı / yazılı sipariş sözleşmesi; her varlığın kaydı tutulacak (kısmen: theme-bible §7 + legal-clearance §3)
- [ ] **⚖️ Font lisansları kontrol edildi** — ticari + uygulamaya gömülü kullanım izinli (SIL OFL / Apache / satın alma); kayıt `legal-clearance.md`'ye
- [x] Hedef yaş derecelendirmesi kararı verildi — **12+ / Teen** (hafif tematik şiddet, kan/ölüm yok; kişiselleştirilmiş reklam serbest)
- [ ] **⚖️ Türkçe + İngilizce yerelleştirme** altyapısı (`intl` / ARB); string'lerde "Quoridor" yasağı lint/gözden geçirme kuralı

---

## FAZ 1 — Yerel hot-seat MVP (oynanabilir)

### Kural motoru (`game_core`) — ✅ tamam (51 test geçiyor)
- [x] Board state modeli (7×7 grid, piyon konumları, engeller, sıra, kalan cephanelik puanı) — `BoardState` (immutable)
- [x] Piyon hareket üretimi (ortogonal 1 adım) — `Rules.pawnMoves`
- [x] Zıplama + koşullu çapraz atlama kuralları (rules.md §4.2)
- [x] Engel yerleştirme geçerliliği (sınır, çakışma, tel+tel dik kesişme) — `Rules.canPlaceBarrier`
- [x] **"Yol kapatılamaz" kontrolü** — `Pathfinding.hasPathToRow` (BFS), her engel adayında iki asker için
- [x] Kazanma tespiti — `Rules.applyMove` (hedef satır)
- [x] Seri hale getirme: kompakt hamle notasyonu + tam state (JSON) — `Move`/`Barrier`/`BoardState`/`GameRecord`
- [x] **⚖️ Kod terminolojisi kendi jargonumuzla** (spec terminolojisi; orijinal oyunun özel terimleri yok)
- [x] Unit test seti: hareket/atlama/engel/yol kapatma invaryantı/kazanma/serialization round-trip
- [x] Property-based test: 25 rastgele kendi kendine oyun — çökme yok, her canlı durumda ≥1 yasal hamle

### Flame oyun ekranı
- [x] Tahta / grid render + hedef satır tintleri + yasal hamle vurguları — `BoardComponent`
- [~] **Görsel zenginleştirme (sürüyor)** — tümü programatik (Flame/Canvas), ton **sert/gerçekçi** (çamur, toz, is, yıpranma). ① Kamera: tahta sıradaki oyuncuya doğru hafifçe eğilir, sıra değişince yumuşak animasyonla döner (`BoardProjection`, izdüşüm birebir tersinir, testli); piyonlar dik + zemin gölgesi + derinlik ölçeği ✅. ② Zemin dokusu: bir kez bake edilen çamur/benek/krater/yıpranmış ızgara/hedef sektörleri, eğim izdüşümünden geçer ✅. ④ Askerler: "miğferli mevzi" — kazılı toprak taban + miğfer kubbesi (radyal degrade hacim + kenar ışığı) + siper diski; sıra vurgusu zeminde nişan reticle'ı ✅. **Renk revizyonu** (`1d8eaca` — kullanıcı: parlak mavi/kırmızı karakterler savaş alanına ait durmuyor): iki taraf da AYNI mat yıpranmış zeytin-çelik miğfer; tek ayrım miğfere sürülmüş **soluk tanım boyası** (soluk arduvaz / soluk pas kırmızısı) — hafif kubbe kastı + kubbe eğrisini izleyen yıpranmış boya bandı. Aynı biçim, yalnız renk. ⑤ Engeller: mayın (yassı zeytin disk + tetik çubukları + amber işaret) · dikenli tel (direkler + sarkan barbed strand'lar); toprak izi; önizleme hayalet ✅. Ek: ayakta duran her şey (asker + engel) sırası gelen oyuncuya doğru **eğimle döner** (`_liftY`); üst üste binme netliği (yassı mayın + kontur halesi); **`hotSeat` param** (varsayılan true; false = AI modu, tahta sabit P1'e bakar) ✅. ③ Çevre/atmosfer: tahtanın etrafındaki siyah boşluk artık zengin bir no man's land — `_drawEnvironment` (ekran uzayında, tahtadan önce) + `_bakeEnvironment` (silüet bir kez image'e, 0.5·vh bant). Uzak cephe: 3 kademeli sırt hattı + parçalanmış ağaçlar + çökmüş sığınak + dikenli tel engeli (kazık sırası + sarkan tel) + kırık kazık tarlası + devrik top arabası (tekerlek/namlu) + tahta kenarına değen mermi kraterleri; uzak kenarın arkasına yerleşir ve **eğimle taraf değiştirir** (P2 sırasında 180° dönük, karşı oyuncunun bakışında dik). Atmosfer: ölü kapalı-hava degradesi + ufuk parıltısı (silüetleri arkadan aydınlatır) + hafif flare titremesi + 3 katman yatay sürüklenen pus + 4 salınan duman sütunu + alçak duman perdesi + süzülen kül zerreleri (titreşen turuncu korlarla, `_Mote`). `_bakeGroundLayer`: tam genişlikte no man's land zemin katmanı — mermi kraterleri + dikenli tel yumakları + moloz + kenarlarda büyük yıkık araç/sığınak; ufkun yakın tarafına serilir, eğimle taraf değiştirir, tahtanın yanındaki boş kahverengi alanları doldurur. Ateş ufuktan alındı → tahtanın YANINDAKİ / ÖNÜNDEKİ zeminde 4 nokta (`_drawFire`: yer parıltısı + oynayan alev + yükselen ince duman). `_drawAshOverlay`: sahanın üstüne düşen kül + kor, render sonunda. Yakın ön plan: SADECE tahta yakın kenarında ince gölge dudağı. `nearBias` 0.09. `hotSeat:false` (AI) sabit P1 kenarı. **Performans** (commit `1105083` — "büyük ölçüde yavaşlamış"): sebep kare başına ~18 `MaskFilter.blur`; hepsi bir kez bake edilen radyal ışık lekesi sprite'ıyla değiştirildi (`_glowBlob`, blur yok), duman degrade dolgulu, shader/boya önbellek, `_bakedForSize` guard, sayılar düşük. Blur ~18→~2; telefon 60fps, geniş masaüstü ~58-60. "Partiküller" kapalı = sıfır efekt = tam hız. **Kırpma** (commit `50ec52f` — "panelin önüne siyah kadran geliyor"): Flame `GameWidget` kırpmaz → çevre katmanları tuval dışına, P2 paneline taşıyordu; `GameWidget` `ClipRect` içine alındı. **Engel çizimi** (commit `a77e8b6` — "mayın/tel koyarken ciddi kasma"): `_drawMine` toprak yatağı kare-başı blur → `_glowBlob`; `_drawBarrierScar` benekleri önbelleğe alındı (kare-başı RNG yok); `_drawWire` boyaları döngü dışına — 60fps. **Sıra dönüşü kasması** (commit `db54d7e` — "kameranın o hareketi sırasında kasma"): ilk dönüşlerde CanvasKit/dart2js ilk-çalıştırma derleme takılması + genel yüksek kare maliyeti. (1) shader ısıtma — `_priming`: ilk kareler eğimi tüm aralıkta gezip sahte engel/önizleme çizer, `game_screen` `board.primeReady`'e kadar örtük tutar; (2) `_tiltAnimating` → dönüşte tahta blit'i `FilterQuality.low`; (3) `_PlayerPanel` gövdeleri `Offstage` ile ağaçta kalır. İlk 1-2 dönüşte küçük ısınma kalır. Debug web çok yavaş — `--release` ile test. **Engel koyduktan sonraki dönüş** (commit `d9fe199`): (a) `AnimatedSize` panel animasyonu `GameWidget`'ı her kare boyutlandırıp 3 dokuyu yeniden bake ettiriyordu → bake artık boyut oturunca (`_pendingBakeSize`); (b) `_apply` her hamlede gereksiz `Rules.applyMove(validate:true)` (~144 BFS) çağırıyordu → `validated:true` ile atlandı; (c) `AnimatedBuilder` tüm Column'u (GameWidget dahil) yeniden kuruyordu → yalnız paneller+sayaç. Engel-dönüşü kasması ~yarıya indi.

**Ayarlar** (yeni, `lib/settings.dart` + `shared_preferences`): `AppSettings` tekil (timed/sound/music/particles), açılışta yüklenir, kalıcı. Ana ekranda dişli ikonu → alttan panel: Ses / Müzik (yakında) / Partiküller. "Partiküller" kapalı = ateş/duman/kül/kor/sürüklenen pus çizilmez; sabit cephe manzarası kalır. Süreli mod da artık kalıcı.

**⑦ Ana menü sert geçişi bitti** (commit `6a1e035` + `51ef03d` + `6e06dd0`): `lib/ui/app_theme.dart` (yeni) — `AppPalette` + `buildAppTheme()` (amber vurgu, koyu yüzeyler); placeholder yeşil tohum gitti (oyun içi mod çipleri de amber oldu). Ana menü butonu → köşeli amber "saha tabelası"; "Süreli mod" → çizgili kutu + amber switch. `ThemeBackdrop` yalın 3-poligon → atmosferik cephe sahnesi (siper silüeti + savaş enkazı + çamurlu ön plan + tehlike noktaları + "sektör haritası" hayalet tahta); statik, animasyonsuz — yükleme ekranları da hafif kalır. **Kül efekti** (`6e06dd0`, kullanıcı isteği): `lib/ui/ash_fall.dart` (yeni) `AshFall` — oyun içindeki `_drawAshOverlay`'in menü karşılığı; kendi `Ticker`'ıyla döner (yalnız boya), düşen kül + titreşen kor + ufukta 2 nabızlı yangın parıltısı; "Partiküller" kapalıyken hiç kurulmaz (sabit sahne kalır, oyunla aynı). Ayrıca `_MenuEntrance` — başlık/butonlar açılışta bir kez yumuşak belirir.

**⑥ Oyun içi panel + çipler + eylem çubuğu bitti** (commit `1d5a1b7`; kullanıcı: tur sayacına dokunma, paneller + Onayla/Döndür/İptal olsun, sonra hamle animasyonu): `_PlayerPanel` "cephe konsolu" — opak koyu yüzey + hafif degrade + `_TrenchEdge` (tahtaya bakan kenarda tarafın soluk boya bandı + perçin sırası, `CustomPaint`). `_ModeChip` yuvarlak Material → köşeli: seçili amber basılı levha (üst ışık + kalın alt kenar, "saha tabelası" diliyle bir), pasif `surfaceHi` + ince çerçeve. `_FieldButton` (yeni) Döndür/Onayla/İptal aynı dile (hayalet / amber levha / yalnız-ikon). `_ArmoryTag` (yeni). `AppPalette.p1/p2` parlak `#3E6E9E`/`#A2433B` → soluk `#47607A`/`#8A4A3E` (asker miğferleriyle aynı; `_Faction` ile eşleşir). **Tur sayacı (`_TurnTimer`) dokunulmadı.** Tahta hedef-satır tint'leri ve menü `_StandoffMark` bilerek parlak kaldı. **Sıradaki:** hamle animasyonu (piyon kayarak + toz).
- [~] **⚖️ İki asker piyon** — şimdilik placeholder daire; özgün low-poly varlık sonra (Faz 5 tema)
- [x] **⚖️ Mayın (1-seg) yerleştirme UI** — mod düğmesi + snap + önizleme (yeşil=yasal) + Onayla/Döndür/İptal; **görsel: yarı gömülü zeytin gövde + tetik çubukları + amber işaret + kazılmış toprak izi**
- [x] **⚖️ Dikenli tel (2-seg) yerleştirme UI** — aynı akış; **görsel: eğik direkler + sarkan barbed strand'lar + dikenler + toprak izi**
- [x] Tur göstergesi + kalan cephanelik sayacı (sıradaki oyuncunun) + geri al düğmesi
- [x] **İki taraflı hot-seat düzeni** — telefon masaya yatık; alt panel P1 (düz), üst panel P2 (180° dönük); sırası olmayan oyuncunun paneli katlanır (kilitli şerit)
- [x] **Süreli mod** — her tur 30 sn, sağ kenarda azalan çubuk + iki uçta okunur sayaç; süre dolunca asker hedefe doğru otomatik ilerler; ana menüde aç/kapa
- [ ] Hamle animasyonları — henüz yok (piyon anında ışınlanıyor); **sıradaki iş** (kullanıcıyla birlikte)
- [x] Kazanma diyaloğu + yeniden başlat

### Uygulama kabuğu
- [x] Ana menü — sert geçiş yapıldı: `AppPalette`/`buildAppTheme` (amber vurgu, yeşil tohum kaldırıldı), köşeli "saha tabelası" buton, zenginleştirilmiş `ThemeBackdrop` (siper silüeti + savaş enkazı + çamurlu ön plan + sektör-haritası hayalet tahta). Tam Ayarlar ekranı + dil seçimi sonra
- [x] **Ortak yükleme görünümü** (`lib/ui/loading_view.dart`) — ana menüyle aynı arka plan + temaya uygun radar spinner + "Yükleniyor"; açılış hazırlığında (`_Bootstrap`) ve Flame sahnesi yüklenirken kullanılır. Sonraki fazlar (online lobi, yapay zeka hazırlığı) aynı görünümü yeniden kullanır.
- [~] Ayarlar — ana ekranda dişli → alttan panel; Partiküller (aktif) + Ses/Müzik (yakında) + Süreli mod; `shared_preferences` ile kalıcı. Kalan: dil seçimi, ses/müzik hattı bağlanınca gerçek işlev
- [~] **⚖️ Tek tema** — placeholder renk paleti (`docs/theme-bible.md` §3); özgün varlıklar sonra
- [~] Geri alma (undo) — çalışıyor; onay diyaloğu henüz yok
- [x] Dokunma etkileşimi: mod düğmeleri (Hareket / Mayın·1 / Tel·2), tahta dokunması → hamle/önizleme
- [ ] **Çıkış kriteri:** iki kişi aynı cihazda kurallara uygun tam oyun oynuyor *(oynanış + hot-seat düzeni + süre tamam; kalan: animasyon + özgün görseller + ayarlar ekranı)*

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
