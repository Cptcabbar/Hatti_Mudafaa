# Hattı Müdafaa — Tema Kılavuzu (theme bible) · TASLAK

> Görsel/işitsel yön. Faz 5'teki "tema motoru" bu değerleri config'ten okur;
> ilk tema ("Cephe") burada tanımlanır. **⚖️ Tüm varlıklar özgün veya lisanslı;
> kayıt `docs/legal-clearance.md` §3–4.**

## 1. Ton ve kurgu

- **Jenerik askeri / cephe hattı.** Belirsiz dönem ve coğrafya, isimsiz askerler,
  hayali bir cephe. Gerçek bir savaş, ordu, ülke **temsil edilmez**.
- Ağır savaş draması değil — **sade, stratejik, "saha" hissi**. Sakin, ağırbaşlı.
- **12+ / Teen.** Patlama/toz/kıvılcım efektleri olabilir; kan, yaralanma, ölüm
  gösterimi **yok**. Oyunda asker zaten ölmez — yalnızca ilerler ve mevzi tutar.

## 2. Görsel stil

- **Low-poly render → 2B.** Öğeler Blender'da düşük poligonlu modellenir,
  sabit açıyla (hafif izometrik, ~30°) render edilir, sprite/atlas olarak gömülür.
- **Tek yönlü ışık** (sol-üst), yumuşak gölge + hafif ambient occlusion.
- Düz renk yüzeyler, minimum doku; okunabilirlik > gerçekçilik.
- Faz 1'de **placeholder primitifler** (renkli daireler/dikdörtgenler) kullanılır;
  rendered art hazır oldukça değiştirilir. Kural motoru veya arayüz mantığı
  görsele bağlı değildir.

## 3. Palet (placeholder — config'e taşınacak)

| Rol | Değer | Not |
|---|---|---|
| Zemin / tahta | `#6B6141` haki-toprak | parseller arası ince çizgi `#574F35` |
| Oyuncu 1 (Mavi) | `#3E6E9E` | piyon + vurgular |
| Oyuncu 2 (Kırmızı) | `#A2433B` | piyon + vurgular |
| Tehlike / mayın | `#E0A72E` turuncu-sarı | uyarı vurgusu |
| Nötr UI | `#1E1B14` zemin, `#EDE7D6` metin | koyu tema öncelikli |

## 4. Öğeler

- **Tahta (7×7):** savaş alanı parselleri; hafif krater/çukur dokusu, kenarlarda
  kum torbası / siper çizgisi. Kesişimler engel yuvası olarak belli belirsiz işaretli.
- **Asker piyon (2 renk):** low-poly figür — miğfer + sırt çantası silueti yeterli.
  Yüz detayı yok. **⚖️ Gerçek üniforma, rütbe işareti, amblem yok.**
- **Mayın:** küçük low-poly kara mayını (disk + tetik), yere hafif gömülü. 1 kenar.
- **Dikenli tel:** iki kazık + tel örgü, 2 kare uzunluğunda.
- **Hedef hattı:** karşı kenarda ele geçirilecek mevzi — jenerik sinyal direği /
  anten (gerçek bayrak değil).

## 5. Animasyon ve ses

- **Animasyon:** piyon adımı (kısa sıçrama + toz), mayın yerleşme (gömülme "tık"),
  tel yerleşme (gerilme "şak"), kazanma (mevziye ulaşınca sinyal fişeği).
- **Ses:** hafif ortam (rüzgâr, uzak gök gürültüsü), UI tık sesleri, engel sesleri.
  **Ağır silah sesi / çığlık yok** (ton + 12+). royalty-free + ticari + gömme lisanslı.

## 6. Adlandırma

- TR mağaza: **Hattı Müdafaa**
- Uluslararası mağaza: İngilizce başlık — _seçilecek_ (aday: "Trench Line",
  "Hold the Line", "No Man's Land", "Frontline"). Marka taramasına dahil.

## 7. Varlık üretim hattı

```
Blender (.blend, low-poly)  →  ortografik/izometrik render (PNG @1x @2x @3x)
                            →  sprite atlas (flame_texturepacker uyumlu)
```
- Kaynak `.blend` → `art/` · export'lar → `assets/`
- Her varlık `legal-clearance.md` §3'te kayıtlı (kaynak, lisans, sözleşme).
