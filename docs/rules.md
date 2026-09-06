# Kapalı Yol — Oyun Kuralları Spesifikasyonu (canonical)

> **Bu belge sıfırdan, kendi ifademizle yazılmıştır.** Hiçbir ticari oyunun kural kitapçığı
> metni, örnekleri veya diyagram anlatımı kaynak alınmamıştır. Terminoloji bu projeye özgüdür.
>
> Bu dosya **tek doğruluk kaynağıdır**: `game_core`, `game_ai`, online doğrulama ve arayüz
> hepsi buradaki tanımları uygular. Bir uç durum burada yazılı değilse, önce buraya yazılır.
>
> Durum: **v1 — KESİNLEŞTİ** (2026-09-06). Cephanelik puanı ve tahta boyutu playtest'te
> ayarlanabilir sayılardır; `game_core` bunları `GameConfig`'ten alır, sabit yazmaz.

---

## 1. Tema ve amaç

İki asker, mayınlı bir savaş alanının karşılıklı iki ucundadır. Her oyuncunun amacı
**kendi askerini tahtanın karşı kenarına ulaştırmaktır**. Oyuncular sırayla ya askerini
ilerletir ya da rakibin yolunu uzatmak için sahaya **mayın** veya **dikenli tel** yerleştirir.
Yol tamamen kapatılamaz — rakibe her zaman en az bir geçiş bırakılmak zorundadır.

---

## 2. Tahta ve koordinat sistemi

- Tahta **7 × 7 kare** (`GameConfig.boardSize = 7`).
- Sütunlar soldan sağa **a–g**, satırlar alttan yukarı **1–7**. Bir kare `d4` gibi gösterilir.
- **Kesişim noktaları (pivot):** karelerin köşelerindeki iç noktalar; bir pivot, sol-altındaki
  kareyle anılır. `c3` pivotu = `c3–d3–c4–d4` karelerinin ortak köşesi. Pivot aralığı: **a–f × 1–6**.
- **Oyuncu 1 (Mavi)** başlangıç: `d1`. Hedef: **7. satırdaki herhangi bir kare**.
- **Oyuncu 2 (Kırmızı)** başlangıç: `d7`. Hedef: **1. satırdaki herhangi bir kare**.
- İlk hamleyi **Oyuncu 1** yapar.

---

## 3. Bir turda yapılabilecekler

Sıradaki oyuncu **tam olarak bir** eylem yapar:

1. **Askeri ilerlet** (bkz. §4), veya
2. **Engel yerleştir** — cephaneliğinde yeterli puan varsa (bkz. §5).

Pas geçmek yoktur. Engel puanı kalmadıysa oyuncu ilerlemek zorundadır (yol kapatma yasak
olduğundan her zaman en az bir yasal ilerleme bulunur).

---

## 4. Asker hareketi

### 4.1 Temel hareket
Asker, komşu **4 kareden** birine (yukarı/aşağı/sol/sağ) **bir kare** ilerler. Şu durumlarda
o yöne geçiş **engellidir**:
- Aradaki kenarda bir engel (mayın veya dikenli tel segmenti) varsa, veya
- Hedef kare tahtanın dışındaysa.

### 4.2 Rakiple karşılaşma — atlama
Sıradaki askerin gireceği komşu karede **rakip asker** duruyorsa:

- **Düz atlama:** Rakibin bir arkasındaki kareye (aynı doğrultuda) geçilir — o kare
  tahtadaysa **ve** rakip ile o kare arasında engel yoksa.
- **Koşullu çapraz atlama:** Düz atlama mümkün *değilse* (arka kare tahta dışı **veya**
  rakip ile arka kare arasında engel), asker rakibin **yanındaki iki kareden** birine
  geçebilir — yalnızca **rakip ile o çapraz kare arasındaki kenar engelsizse** ve çapraz
  kare tahtadaysa. "Her zaman çapraz serbest" **değildir**.

Atlama tek eylemdir; zincirleme atlama yoktur.

---

## 5. Engeller

### 5.1 İki engel tipi
| Tip | Kapladığı | Cephanelik maliyeti |
|---|---|---|
| **Mayın** (`mine`) | Komşu iki kare arasındaki **tek kenar** (ayrık nesne, çit değil) | **1 puan** |
| **Dikenli tel** (`wire`) | Bir pivotta birleşen, aynı hat üzerinde **iki ardışık kenar** | **2 puan** |

- Her oyuncunun **cephaneliği** oyun başında **8 puandır** (`GameConfig.armoryPoints = 8`).
  Ayrı dağıtım yok: oyuncu her turda puanı yettiği sürece istediği tipte engel koyar
  (ör. 8 mayın, ya da 4 tel, ya da 2 tel + 4 mayın).
- Cephanelikler **ayrıdır** (ortak havuz değil).
- Puan yetmiyorsa o tip engel konamaz (1 puan kalınca yalnızca mayın konabilir).

### 5.2 Yönelim ve kapsama
Pivot `p` = `(sütun_boşluğu, satır_boşluğu)`, aralık a–f × 1–6.

- **Yatay dikenli tel** `p`: `p` ile aynı satır boşluğundaki iki dikey geçişi kapatır
  — sol kare ile üstü, sağ kare ile üstü. (Örn. `Wc3h` → `c3↔c4` ve `d3↔d4` kapalı.)
- **Dikey dikenli tel** `p`: iki yatay geçişi kapatır. (`Wc3v` → `c3↔d3` ve `c4↔d4` kapalı.)
- **Yatay mayın**: tek bir dikey geçişi kapatır (`Mc3h` → yalnız `c3↔c4`).
- **Dikey mayın**: tek bir yatay geçişi kapatır (`Mc3v` → yalnız `c3↔d3`).

### 5.3 Yerleştirme geçerliliği
Bir engel ancak şu koşulların **tümü** sağlanırsa konabilir:

1. **Sınır:** Tüm kapattığı kenarlar tahtanın içindedir (dikenli tel pivotu a–f × 1–6;
   taşma yok).
2. **Çakışma yasak:** Kapatacağı kenarlardan hiçbiri **zaten kapalı değildir** (başka bir
   mayın veya tel segmentiyle). Bu kural, üst üste binen dikenli telleri de otomatik eler.
3. **Tel + tel dik kesişme yasak:** İki dikenli tel **aynı pivotta** dik açıyla kesişemez
   (artı `+` şekli yok). *(Mayın bu kısıtın dışındadır — küçük ayrık nesnedir; farklı bir
   kenarı kapattığı sürece dik bir engelin yanından geçebilir.)*
4. **Yol kapatma yasağı:** Yerleştirmeden sonra **her iki asker** de kendi hedef satırına
   ulaşabilecek en az bir yola sahip olmalıdır (BFS ile doğrulanır). Aksi halde yasadışıdır.

---

## 6. Oyunun bitişi

- Bir asker **hedef satırındaki herhangi bir kareye** ulaştığında o oyuncu **kazanır**;
  oyun anında biter.
- Beraberlik yoktur.
- **Yerel + AI modu:** tur süresi yoktur.
- **(Online)** Tur sayacı ve terk/bağlantı-kopması toleransı Faz 4'te belirlenecektir
  (varsayılan beklenti: kalıcı kopan taraf yeniler).

---

## 7. Hamle notasyonu (seri hale getirme)

Kompakt, metin tabanlı; tekrar oynatma ve online senkron için.

- **İlerleme:** hedef kare — `d2`, `e4` … Atlama da hedef kareyle yazılır (ara adım ima edilir).
- **Mayın:** `M` + kare + yön (`h`/`v`) — `Mc3h`, `Mf1v`.
- **Dikenli tel:** `W` + pivot + yön (`h`/`v`) — `Wc3h`, `Wa6v`.
- Bir oyun = `GameConfig` + başlangıç konfigürasyonu + sıralı hamle listesi.
- **Tam durum (state) JSON'u** ayrıca tutulur: `config`, asker konumları, tüm engeller,
  sıra, her oyuncunun kalan cephanelik puanı, hamle sayacı, kazanan.

---

## 8. Yapılandırılabilir sayılar (`GameConfig`)

| Alan | v1 değeri | Not |
|---|---|---|
| `boardSize` | 7 | Kare tahta kenarı |
| `armoryPoints` | 8 | Oyuncu başına engel puanı |
| `mineCost` | 1 | |
| `wireCost` | 2 | |
| `startP1` / `startP2` | `d1` / `d7` | Ana sıra ortası |

> Playtest sonrası ilk beklenen ayar: 7×7'de 8 puan yoğun gelirse `armoryPoints` → 6.

---

## 9. Belirsizlik çözümü sırası

Bir durum net değilse:
1. Bu belgeye bak.
2. Burada yoksa: karar ver, **buraya yaz**, sonra kodla.
3. `game_core` testine bir vaka ekle.

---

## Karar günlüğü

- **2026-09-06** — v1 kesinleşti: 7×7 tahta, `d1`/`d7` başlangıç, Oyuncu 1 başlar;
  8 puan cephanelik (mayın 1 / tel 2, ayrı dağıtım yok); koşullu çapraz atlama;
  engel kuralları §5.3 (çakışma yasak, tel+tel dik kesişme yasak, mayın serbest kesişir);
  yerel modda süre yok.
