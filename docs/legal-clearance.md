# Kapalı Yol — Yasal Uyum Kayıt Defteri (legal clearance)

> Bu dosya, projenin telif ve marka açısından temiz olduğunu **kanıtlayan kayıtların**
> arşividir. ROADMAP'teki her `⚖️` maddesi tamamlandığında ilgili kanıt (ekran görüntüsü
> linki, lisans dosyası yolu, karar gerekçesi) buraya işlenir.
>
> **Bu bir hukuki mütalaa değildir.** Ticari yayın öncesi, özellikle nihai isim/logo için
> bir fikri mülkiyet avukatından kısa bir ön inceleme alınması önerilir.

---

## 1. Hukuki zemin (özet)

- **Oyun mekaniği / kuralları / sistemleri telif hakkıyla korunmaz.** Bir oyunu "aynı
  şekilde oynanacak" biçimde yeniden yapmak; kelimeleri, sanatı ve bileşenleri kopyalamamak
  kaydıyla hukuken serbesttir (ABD mahkeme içtihadı ve genel uygulama). Kaynaklar: ROADMAP §Kaynaklar.
- **Korunan ve kaçınılan unsurlar:**
  1. Kural kitapçığı metni (spesifik ifade) → kendi metnimizi yazdık: `docs/rules.md`.
  2. Görsel/grafik varlıklar, tahta görünümü, bileşen biçimleri, renk paleti, font (trade dress).
  3. **"Quoridor" markası** ve karıştırma ihtimali olan türevleri.
- **Patent:** Quoridor 1997 yayını → olası patentler süresi dolmuş. Doğrulama: bkz. §5.

---

## 2. İsim / marka taraması

**Aday isim(ler):** _(doldurulacak — geçici kod adı: "Kapalı Yol")_

| Kaynak | Tarih | Sorgu | Sonuç | Kanıt |
|---|---|---|---|---|
| TÜRKPATENT marka araması | | | | |
| EUIPO eSearch plus | | | | |
| USPTO TESS | | | | |
| WIPO Global Brand Database | | | | |
| Google Play — isim araması | | | | |
| App Store — isim araması | | | | |
| Genel web + sosyal medya | | | | |
| Alan adı (.com / .com.tr / .app) | | | | |

**Nice sınıfları hedefi:** 9 (bilgisayar oyunu yazılımı), 28 (oyunlar ve oyuncaklar).

**Değerlendirme / karar:** _(temiz mi? başvurulacak mı? bütçe?)_

---

## 3. Görsel varlık envanteri

| Varlık | Kaynak (özgün / CC0 / satın alma / sipariş) | Lisans | Dosya / sözleşme yolu | Not |
|---|---|---|---|---|
| Asker piyon (Oyuncu 1) | | | | gerçek ordu amblemi/logo/kişi benzerliği YOK |
| Asker piyon (Oyuncu 2) | | | | |
| Mayın görseli | | | | özgün |
| Dikenli tel görseli | | | | özgün |
| Tahta / arka plan (Tema 1) | | | | Gigamic görsel dili referans alınmadı |
| Uygulama ikonu | | | | |
| Menü / UI ikonları | | | | |

---

## 4. Font / ses / müzik lisansları

| Öğe | Kaynak | Lisans | Ticari kullanım | Uygulamaya gömme izni | Kanıt |
|---|---|---|---|---|---|
| Ana font | | | | | |
| Başlık fontu | | | | | |
| Ses efektleri | | | | | |
| Müzik | | | | | |

---

## 5. Patent doğrulaması

| Kaynak | Tarih | Sorgu | Sonuç |
|---|---|---|---|
| Google Patents ("Quoridor" / Mirko Marchesi / Gigamic) | | | |
| Espacenet | | | |

**Sonuç:** _(beklenen: aktif engelleyici patent yok)_

---

## 6. Üçüncü parti kod bağımlılıkları

| Paket | Sürüm | Lisans | Attribution gerekli mi | Not |
|---|---|---|---|---|
| flame | | BSD-3 | | |
| google_mobile_ads | | | | |
| supabase_flutter | | | | |
| in_app_purchase | | | | |

> Yayın öncesi: `flutter pub deps` çıktısı + tüm lisanslar `NOTICE` dosyasında; uygulama
> içi "Lisanslar" ekranı (`showLicensePage`).

---

## 7. Mağaza metni taraması

- [ ] Başlık, kısa açıklama, uzun açıklama, ASO anahtar kelimeleri, promosyon metni,
      ekran görüntüsü yazıları (TR + EN) — "Quoridor", "Quor", "corridor" ve
      "klon/benzeri/alternatifi" ifadeleri **yok**.
- [ ] Otomatik tarama (basit grep/CI kuralı) eklendi.

---

## 8. Karar günlüğü

| Tarih | Karar | Gerekçe |
|---|---|---|
| | Mekanik Quoridor-türevi kullanılacak | Mekanik/kural telifle korunmuyor |
| | Tahta 7×7 (9×9 değil) | Bilinçli ayrışma + mobil oynanış |
| | Engel: 1-seg mayın + 2-seg dikenli tel | Askeri tema + orijinalden ayrışma |
| | İsim: TBD | Marka taraması sonrası |
