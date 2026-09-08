// Oyun ses efektlerini (SFX) sıfırdan sentezler → assets/audio/sfx/*.wav
//
//   node tool/gen_sfx.mjs
//
// Hepsi kısa (<0.5 sn), mono, 44.1 kHz, 16-bit PCM. Kayıt yok — saf DSP:
// filtrelenmiş gürültü + zarf + rezonatör. Üretilen .wav'lar commit'lenir;
// bu script yalnızca yeniden üretim / ince ayar için.
//
// ⚖️ Tamamen özgün, üretilmiş içerik — hiçbir örnek/kütüphane sesi kullanılmadı.

import fs from 'node:fs';
import path from 'node:path';

const SR = 44100;
const OUT = path.resolve('assets/audio/sfx');
fs.mkdirSync(OUT, { recursive: true });

// --- yardımcılar -----------------------------------------------------------
const rnd = (seed => () => {
  // deterministik PRNG (mulberry32)
  seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
})(1337);

const white = () => rnd() * 2 - 1;

/** 2. derece bandpass (biquad, RBJ) — tek örnek işler, durum kapanışta tutulur. */
function makeBandpass(f0, Q) {
  const w0 = (2 * Math.PI * f0) / SR;
  const alpha = Math.sin(w0) / (2 * Q);
  const b0 = alpha, b1 = 0, b2 = -alpha;
  const a0 = 1 + alpha, a1 = -2 * Math.cos(w0), a2 = 1 - alpha;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  return (x) => {
    const y = (b0 / a0) * x + (b1 / a0) * x1 + (b2 / a0) * x2
      - (a1 / a0) * y1 - (a2 / a0) * y2;
    x2 = x1; x1 = x; y2 = y1; y1 = y;
    return y;
  };
}

/** tek kutuplu alçak geçiren */
function makeLowpass(fc) {
  const a = Math.exp((-2 * Math.PI * fc) / SR);
  let z = 0;
  return (x) => (z = (1 - a) * x + a * z);
}

const env = (t, atk, tau) =>
  (t < atk ? t / atk : 1) * Math.exp(-(Math.max(0, t - atk)) / tau);

/** yükseltilmiş kosinüs pencereli kısa "tane" (kar çıtırtısı için) */
function grain(buf, centerSec, durSec, amp, fc) {
  const c = (centerSec * SR) | 0;
  const half = (durSec * SR) / 2;
  const lp = makeLowpass(fc);
  for (let i = -half; i <= half; i++) {
    const idx = c + i;
    if (idx < 0 || idx >= buf.length) continue;
    const w = 0.5 + 0.5 * Math.cos((Math.PI * i) / half);
    buf[idx] += amp * w * lp(white());
  }
}

function render(seconds, fn) {
  const n = (seconds * SR) | 0;
  const buf = new Float32Array(n);
  fn(buf, n);
  // yumuşak sınırlayıcı + tepe normalizasyonu + 4 ms çıkış fade
  let peak = 0;
  for (let i = 0; i < n; i++) {
    buf[i] = Math.tanh(buf[i] * 1.6);
    if (Math.abs(buf[i]) > peak) peak = Math.abs(buf[i]);
  }
  const g = peak > 0 ? 0.92 / peak : 1;
  const fade = (0.004 * SR) | 0;
  for (let i = 0; i < n; i++) {
    let s = buf[i] * g;
    if (i > n - fade) s *= (n - i) / fade;
    if (i < 32) s *= i / 32; // tık önleyici giriş
    buf[i] = s;
  }
  return buf;
}

function writeWav(name, buf) {
  const n = buf.length;
  const data = Buffer.alloc(44 + n * 2);
  data.write('RIFF', 0); data.writeUInt32LE(36 + n * 2, 4); data.write('WAVE', 8);
  data.write('fmt ', 12); data.writeUInt32LE(16, 16); data.writeUInt16LE(1, 20);
  data.writeUInt16LE(1, 22); data.writeUInt32LE(SR, 24);
  data.writeUInt32LE(SR * 2, 28); data.writeUInt16LE(2, 32);
  data.writeUInt16LE(16, 34); data.write('data', 36);
  data.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    const s = Math.max(-1, Math.min(1, buf[i]));
    data.writeInt16LE((s * 32767) | 0, 44 + i * 2);
  }
  fs.writeFileSync(path.join(OUT, name), data);
  console.log(`  ${name}  ${(n / SR * 1000) | 0}ms  ${data.length}b`);
}

// --- 1) Toprakta adım -----------------------------------------------------
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

// --- 2) Karda adım (çıtırtı + gıcırtı) ----------------------------------
writeWav('step_snow.wav', render(0.26, (buf, n) => {
  // yumuşak ayak basışı
  const lp = makeLowpass(2600);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    buf[i] += Math.sin(2 * Math.PI * 85 * t) * env(t, 0.001, 0.02) * 0.22;
    buf[i] += lp(white()) * env(t, 0.001, 0.03) * 0.28;
  }
  // ~14 rastgele çıtırtı tanesi (ilk 170 ms)
  for (let k = 0; k < 14; k++) {
    grain(buf, 0.004 + rnd() * 0.17, 0.006 + rnd() * 0.01,
      0.5 + rnd() * 0.5, 3000 + rnd() * 4000);
  }
  // kayan bandpass gıcırtı
  const bp = makeBandpass(2200, 6);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const drift = 2200 + 500 * Math.sin(t * 24);
    // yaklaşık: sabit merkezli bp yeterince "gıcırtılı" veriyor
    buf[i] += bp(white()) * env(t, 0.005, 0.08) * 0.18 * (drift / 2200);
  }
}));

// --- 3) Mayın yerleştirme (toprağa bas + metal tık) --------------------
writeWav('mine.wav', render(0.34, (buf, n) => {
  const lp = makeLowpass(700);
  const partials = [1850, 2790, 4120];
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const click = white() * env(t, 0, 0.003) * 0.5;
    const press = lp(white()) * env(t, 0.003, 0.055) * 0.7;
    let metal = 0;
    for (let p = 0; p < partials.length; p++) {
      metal += Math.sin(2 * Math.PI * partials[p] * t) *
        Math.exp(-t / (0.11 - p * 0.02));
    }
    metal *= env(t, 0.004, 0.12) * 0.22;
    buf[i] = click + press + metal;
  }
}));

// --- 4) Dikenli tel çekme (gerilim twang + metalik hışırtı) -----------
writeWav('wire.wav', render(0.5, (buf, n) => {
  const bp = makeBandpass(2600, 3);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    // gerilirken hafif düşen perde
    const f = 322 * (1 - 0.05 * Math.min(1, t / 0.12));
    const twang =
      (Math.sin(2 * Math.PI * f * t) * Math.exp(-t / 0.22) +
        0.5 * Math.sin(2 * Math.PI * 2 * f * t) * Math.exp(-t / 0.12) +
        0.3 * Math.sin(2 * Math.PI * 3 * f * t) * Math.exp(-t / 0.08)) * 0.5;
    // titreşen metalik hışırtı (7 Hz tremolo)
    const rasp = bp(white()) * Math.exp(-t / 0.3) *
      (0.6 + 0.4 * Math.sin(2 * Math.PI * 7 * t)) * 0.3;
    // alçak gıcırtı
    const creak = Math.sin(2 * Math.PI * 118 * t) * env(t, 0.002, 0.05) * 0.2;
    buf[i] = twang + rasp + creak;
  }
}));

console.log('bitti →', OUT);
