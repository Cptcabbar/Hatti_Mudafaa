// Oyun ses efektlerini (SFX) sıfırdan sentezler → assets/audio/sfx/*.wav
//
//   node tool/gen_sfx.mjs
//
// Hepsi kısa, mono, 44.1 kHz, 16-bit PCM. Kayıt yok — saf DSP: filtrelenmiş
// gürültü + zarf + rezonatör. Üretilen .wav'lar commit'lenir; bu script
// yalnızca yeniden üretim / ince ayar için.
//
// ⚖️ Tamamen özgün, üretilmiş içerik — hiçbir örnek/kütüphane sesi kullanılmadı.
//
// NOT: step_dirt.wav ve mine.wav kullanıcı tarafından onaylandı ve
// "kilitli"dir — bu script onları ÜZERİNE YAZMAZ (yalnızca yoksa üretir).
// Yeniden üretmek istersen ilgili .wav'ı sil, sonra çalıştır.

import fs from 'node:fs';
import path from 'node:path';

const SR = 44100;
const OUT = path.resolve('assets/audio/sfx');
fs.mkdirSync(OUT, { recursive: true });
const LOCKED = new Set(['step_dirt.wav', 'mine.wav']);

// --- yardımcılar -----------------------------------------------------------
let _s = 1337;
const rnd = () => {
  _s |= 0; _s = (_s + 0x6D2B79F5) | 0;
  let t = Math.imul(_s ^ (_s >>> 15), 1 | _s);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const white = () => rnd() * 2 - 1;
const seedRnd = (v) => { _s = v | 0; };

/** State-variable filtre (Chamberlin) — merkez frekans örnek örnek modüle
 *  edilebilir. .band = bandpass, .high = highpass, .low = lowpass. */
function makeSVF() {
  let low = 0, band = 0;
  return (x, f0, Q) => {
    const fc = 2 * Math.sin((Math.PI * Math.min(f0, SR * 0.45)) / SR);
    const q = 1 / Q;
    const high = x - low - q * band;
    band += fc * high;
    low += fc * band;
    return { low, band, high };
  };
}
function makeLowpass(fc) {
  const a = Math.exp((-2 * Math.PI * fc) / SR);
  let z = 0;
  return (x) => (z = (1 - a) * x + a * z);
}

const env = (t, atk, tau) =>
  (t < atk ? t / atk : 1) * Math.exp(-Math.max(0, t - atk) / tau);

/** yükseltilmiş kosinüs pencereli kısa gürültü tanesi */
function grain(buf, centerSec, durSec, amp, fc) {
  const c = (centerSec * SR) | 0;
  const half = Math.max(2, (durSec * SR) / 2);
  const lp = makeLowpass(fc);
  for (let i = -half; i <= half; i++) {
    const idx = c + i;
    if (idx < 0 || idx >= buf.length) continue;
    const w = 0.5 + 0.5 * Math.cos((Math.PI * i) / half);
    buf[idx] += amp * w * lp(white());
  }
}
/** kısa tık (mekanik) */
function tick(buf, atSec, amp, fc, Q) {
  const svf = makeSVF();
  const c = (atSec * SR) | 0;
  const n = (0.006 * SR) | 0;
  for (let i = 0; i < n; i++) {
    const idx = c + i;
    if (idx < 0 || idx >= buf.length) continue;
    const e = Math.exp(-i / (0.0009 * SR));
    buf[idx] += amp * e * svf(white(), fc, Q).band;
  }
}

function render(seconds, fn) {
  const n = (seconds * SR) | 0;
  const buf = new Float32Array(n);
  fn(buf, n);
  let peak = 0;
  for (let i = 0; i < n; i++) {
    buf[i] = Math.tanh(buf[i] * 1.5);
    if (Math.abs(buf[i]) > peak) peak = Math.abs(buf[i]);
  }
  const g = peak > 0 ? 0.92 / peak : 1;
  const fade = (0.004 * SR) | 0;
  for (let i = 0; i < n; i++) {
    let s = buf[i] * g;
    if (i > n - fade) s *= (n - i) / fade;
    if (i < 24) s *= i / 24;
    buf[i] = s;
  }
  return buf;
}

function writeWav(name, buf) {
  if (LOCKED.has(name) && fs.existsSync(path.join(OUT, name))) {
    console.log(`  ${name.padEnd(16)} (kilitli — atlandı)`);
    return;
  }
  const n = buf.length;
  const data = Buffer.alloc(44 + n * 2);
  data.write('RIFF', 0); data.writeUInt32LE(36 + n * 2, 4); data.write('WAVE', 8);
  data.write('fmt ', 12); data.writeUInt32LE(16, 16); data.writeUInt16LE(1, 20);
  data.writeUInt16LE(1, 22); data.writeUInt32LE(SR, 24);
  data.writeUInt32LE(SR * 2, 28); data.writeUInt16LE(2, 32);
  data.writeUInt16LE(16, 34); data.write('data', 36); data.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    const s = Math.max(-1, Math.min(1, buf[i]));
    data.writeInt16LE((s * 32767) | 0, 44 + i * 2);
  }
  fs.writeFileSync(path.join(OUT, name), data);
  console.log(`  ${name.padEnd(16)} ${((n / SR) * 1000) | 0}ms  ${data.length}b`);
}

// =========================================================================
// 1) Toprakta adım  (BEĞENİLDİ — dokunma)
// =========================================================================
seedRnd(101);
writeWav('step_dirt.wav', render(0.19, (buf, n) => {
  const lp = makeLowpass(900);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const sub = Math.sin(2 * Math.PI * 62 * t) * env(t, 0.001, 0.03) * 0.5;
    const body = lp(white()) * env(t, 0.002, 0.05) * 0.8;
    const scuff = white() * env(t, 0, 0.012) * 0.15;
    buf[i] = sub + body + scuff;
  }
}));

// =========================================================================
// 2) Karda adım  (YENİ — yoğun çıtırtı + soğuk kar gıcırtısı, boğuk değil)
// =========================================================================
seedRnd(202);
writeWav('step_snow.wav', render(0.25, (buf, n) => {
  // hafif temas
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += Math.sin(2 * Math.PI * 140 * t) * env(t, 0.0005, 0.012) * 0.14;
  }
  // yoğun granüler çıtırtı — parlak, geniş bant, ~34 minik darbe (ilk 150 ms)
  for (let k = 0; k < 34; k++) {
    const early = k / 34;
    const pos = 0.002 + Math.pow(rnd(), 1.4) * 0.15;
    const amp = (0.9 - 0.5 * early) * (0.4 + 0.6 * rnd());
    grain(buf, pos, 0.0012 + rnd() * 0.0028, amp, 4000 + rnd() * 6000);
  }
  // "ıyk" — sıkışan karın gıcırtısı: modülasyonlu dar bandpass gürültü
  const svf = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    if (t > 0.16) break;
    const f = 950 + 550 * Math.sin(2 * Math.PI * 34 * t) + 300 * t / 0.16;
    const e = env(t, 0.006, 0.05);
    buf[i] += svf(white(), f, 9).band * e * 0.16;
  }
  // ince tiz cızırtı yatağı
  const hp = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += hp(white(), 5500, 0.9).high * env(t, 0.002, 0.035) * 0.12;
  }
}));

// =========================================================================
// 3) Mayın yerleştirme  (BEĞENİLDİ — dokunma)
// =========================================================================
seedRnd(303);
writeWav('mine.wav', render(0.34, (buf, n) => {
  const lp = makeLowpass(700);
  const partials = [1850, 2790, 4120];
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const click = white() * env(t, 0, 0.003) * 0.5;
    const press = lp(white()) * env(t, 0.003, 0.055) * 0.7;
    let metal = 0;
    for (let p = 0; p < partials.length; p++) {
      metal += Math.sin(2 * Math.PI * partials[p] * t) * Math.exp(-t / (0.11 - p * 0.02));
    }
    metal *= env(t, 0.004, 0.12) * 0.22;
    buf[i] = click + press + metal;
  }
}));

// =========================================================================
// 4) Dikenli tel  (YENİ v3 — gergin metal telin "twang"i: temiz inharmonik
//    çınlama + perde kayması, gürültü yalnızca hafif aksan)
// =========================================================================
seedRnd(404);
writeWav('wire.wav', render(0.5, (buf, n) => {
  const B = 0.0009;                    // tel sertliği → inharmonisite (metalik)
  const f0a = 480, f0b = 690;          // gerilirken perde yukarı kayar
  const amp = [1.0, 0.78, 0.6, 0.48, 0.4, 0.32, 0.24, 0.17, 0.12];
  const tau = [0.36, 0.26, 0.21, 0.17, 0.14, 0.115, 0.09, 0.075, 0.06];
  const phase = new Float64Array(amp.length);
  const sizzle = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f0 = f0a + (f0b - f0a) * Math.min(1, t / 0.045);
    let ring = 0;
    for (let p = 0; p < amp.length; p++) {
      const k = p + 1;
      phase[p] += (2 * Math.PI * f0 * k * (1 + B * k * k)) / SR;
      ring += amp[p] * Math.sin(phase[p]) * Math.exp(-t / tau[p]);
    }
    ring *= (t < 0.0025 ? t / 0.0025 : 1) * 0.3;
    // ince metalik sizzle — sadece doku
    const sz = sizzle(white(), 3800, 2).band * Math.exp(-t / 0.11) * 0.08;
    buf[i] = ring + sz;
  }
  // diken şıngırtıları — birkaç kısa tiz metalik tık
  for (const at of [0.008, 0.05, 0.1, 0.165, 0.24]) {
    tick(buf, at, 0.3 + rnd() * 0.18, 2600 + rnd() * 1800, 3.5);
  }
}));

// =========================================================================
// 5) UI switch  (YENİ — mekanik toggle tık)
// =========================================================================
seedRnd(505);
writeWav('ui_switch.wav', render(0.11, (buf, n) => {
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += Math.sin(2 * Math.PI * 1150 * t) * Math.exp(-t / 0.011) * 0.4; // gövde
  }
  tick(buf, 0.0, 0.7, 2600, 1.6);   // basış
  tick(buf, 0.045, 0.32, 2000, 1.8); // oturma
}));

// =========================================================================
// 6) Oyun başlama  (YENİ — kararlı alçak vuruş + yükselen whoosh + uzak tık)
// =========================================================================
seedRnd(606);
writeWav('game_start.wav', render(0.8, (buf, n) => {
  const brown = makeLowpass(500);
  const sweep = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    // bot yere basar
    const thump = (Math.sin(2 * Math.PI * 52 * t) * 0.55 + brown(white()) * 0.4) *
      env(t, 0.001, 0.06);
    // yükselen hava/kararlılık whoosh'u
    const cf = 240 + 1650 * Math.min(1, t / 0.34);
    const swEnv = (t < 0.26 ? t / 0.26 : Math.exp(-(t - 0.26) / 0.24));
    const sw = sweep(white(), cf, 1.3).band * swEnv * 0.32;
    // sonda uzak metalik tık (teçhizat)
    let clink = 0;
    if (t > 0.34) {
      const tt = t - 0.34;
      clink = (Math.sin(2 * Math.PI * 1450 * t) + 0.6 * Math.sin(2 * Math.PI * 2200 * t)) *
        Math.exp(-tt / 0.16) * 0.16;
    }
    // alçak kuyruk
    const tail = Math.sin(2 * Math.PI * 88 * t) * Math.exp(-t / 0.5) * 0.12;
    buf[i] = thump + sw + clink + tail;
  }
}));

// =========================================================================
// 7) UI kağıt  (YENİ — sayfa çevirme "şşk")
// =========================================================================
seedRnd(707);
writeWav('ui_paper.wav', render(0.34, (buf, n) => {
  const bp = makeSVF();
  const bp2 = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    // ana kavrama + çevirme sürtünmesi
    const e1 = (t < 0.04 ? t / 0.04 : Math.exp(-(t - 0.04) / 0.09));
    buf[i] += bp(white(), 2600, 1.1).band * e1 * 0.5;
    // ikinci hafif kayış
    if (t > 0.1) {
      const tt = t - 0.1;
      const e2 = (tt < 0.03 ? tt / 0.03 : Math.exp(-(tt - 0.03) / 0.06));
      buf[i] += bp2(white(), 3400, 1.0).band * e2 * 0.3;
    }
    // sayfa oturur — kısa alçak "fıp"
    buf[i] += Math.sin(2 * Math.PI * 140 * t) * env(Math.max(0, t - 0.18), 0.002, 0.035) * 0.14;
  }
}));

// =========================================================================
// 8) UI çark  (YENİ — ayar / mandal sesi)
// =========================================================================
seedRnd(808);
writeWav('ui_gear.wav', render(0.3, (buf, n) => {
  // hafif mekanik uğultu
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += Math.sin(2 * Math.PI * 95 * t) * Math.exp(-t / 0.22) * 0.08;
  }
  // 5 mandal tıkı
  for (const at of [0.02, 0.068, 0.115, 0.16, 0.205]) {
    tick(buf, at, 0.55 + rnd() * 0.2, 1600 + rnd() * 300, 2.2);
  }
  // ince metalik parıltı
  const sh = makeSVF();
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += sh(white(), 3000, 1.4).band * env(t, 0.005, 0.12) * 0.06;
  }
}));

console.log('bitti →', OUT);
