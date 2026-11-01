"""Moteur de synthèse de HIGHVALE (numpy + scipy) : instruments, batterie,
réverbération à convolution, mixage stéréo et export OGG.

Tout est généré ici : aucune banque de sons externe. Les morceaux sont écrits
dans compose.py ; les effets sonores dans sfx.py.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio")
RNG = np.random.default_rng(1234)


def hz(n):
    """Numéro MIDI (ou nom 'C4', 'F#5', 'Bb3') -> fréquence."""
    if isinstance(n, str):
        n = midi(n)
    return 440.0 * 2 ** ((n - 69) / 12)


NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    base = NAMES[name[0].upper()]
    i = 1
    while i < len(name) and name[i] in "#b":
        base += 1 if name[i] == "#" else -1
        i += 1
    return base + 12 * (int(name[i:]) + 1)


def tt(dur):
    return np.arange(int(dur * SR)) / SR


def adsr(n, a=0.01, d=0.1, s=0.7, r=0.2, sus_time=None):
    """Enveloppe ADSR sur n échantillons (le relâchement occupe la fin)."""
    e = np.full(n, s, dtype=np.float64)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n)
    e[:na] = np.linspace(0, 1, na, endpoint=False) if na else e[:na]
    end_d = min(n, na + nd)
    if end_d > na:
        e[na:end_d] = np.linspace(1, s, end_d - na)
    nr = min(nr, n)
    if nr:
        e[n - nr:] *= np.linspace(1, 0, nr) ** 1.5
    return e


def lp(x, f, order=2):
    b, a = signal.butter(order, min(f / (SR / 2), 0.99), "low")
    return signal.lfilter(b, a, x, axis=-1)


def hp(x, f, order=2):
    b, a = signal.butter(order, min(f / (SR / 2), 0.99), "high")
    return signal.lfilter(b, a, x, axis=-1)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], "band")
    return signal.lfilter(b, a, x, axis=-1)


def peak(x, f, q=5.0):
    b, a = signal.iirpeak(f / (SR / 2), q)
    return signal.lfilter(b, a, x, axis=-1)


# --- Tables d'ondes à bande limitée -------------------------------------------

_TABLES = {}
TABLE_N = 4096


def _table(kind, nharm):
    key = (kind, nharm)
    if key not in _TABLES:
        ph = np.arange(TABLE_N) / TABLE_N * 2 * np.pi
        w = np.zeros(TABLE_N)
        for k in range(1, nharm + 1):
            if kind == "saw":
                w += np.sin(k * ph) / k
            elif kind == "square" and k % 2:
                w += np.sin(k * ph) / k
            elif kind == "tri" and k % 2:
                w += ((-1) ** ((k - 1) // 2)) * np.sin(k * ph) / (k * k)
        w /= np.max(np.abs(w)) + 1e-9
        _TABLES[key] = np.append(w, w[0])
    return _TABLES[key]


def osc(kind, freq, n, phase0=0.0, vib=0.0, vib_rate=5.0, vib_delay=0.3, detune=0.0):
    """Oscillateur (sine, saw, square, tri) avec vibrato différé, sans repliement."""
    t = np.arange(n) / SR
    f = freq * 2 ** (detune / 1200)
    if vib:
        ramp = np.clip((t - vib_delay) / 0.4, 0, 1)
        f = f * (1 + vib * ramp * np.sin(2 * np.pi * vib_rate * t))
    phase = phase0 + np.cumsum(np.broadcast_to(f, (n,)) / SR)
    if kind == "sine":
        return np.sin(2 * np.pi * phase)
    nharm = max(1, min(60, int((SR / 2) / max(freq, 20) * 0.9)))
    tab = _table(kind, nharm)
    idx = (phase % 1.0) * TABLE_N
    return np.interp(idx, np.arange(TABLE_N + 1), tab)


# --- Instruments ----------------------------------------------------------------

def strings(f, dur, vel=0.8, bright=0.6, attack=0.18, release=0.5):
    """Ensemble de cordes : scies désaccordées, vibrato, filtre doux."""
    n = int((dur + release) * SR)
    x = sum(osc("saw", f, n, phase0=RNG.random(), detune=d, vib=0.004, vib_rate=5.2 + RNG.random()) for d in (-9, -3, 4, 10)) / 4
    x = lp(x, 1600 + bright * 5000 + f * 1.5)
    return x * adsr(n, attack, 0.2, 0.85, release) * vel


def pizz(f, dur, vel=0.8):
    n = int((0.6 + 0.2) * SR)
    x = osc("saw", f, n) * 0.6 + osc("tri", f, n) * 0.4
    x = lp(x, 1800 + f)
    return x * np.exp(-np.arange(n) / SR * 7) * adsr(n, 0.004, 0.05, 1.0, 0.05) * vel


def harp(f, dur, vel=0.8):
    """Harpe : partiels harmoniques qui s'éteignent d'autant plus vite qu'ils sont aigus."""
    d = min(3.5, 1.2 + 200 / f)
    n = int(d * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k, a in enumerate([1.0, 0.45, 0.22, 0.12, 0.07, 0.04], start=1):
        x += a * np.sin(2 * np.pi * f * k * t + RNG.random()) * np.exp(-t * (1.4 + k * 1.3))
    x *= adsr(n, 0.003, 0.05, 1.0, 0.05)
    return x * vel * 0.7


def celesta(f, dur, vel=0.8):
    n = int(2.2 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 2.2) + 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 6)
    x += 0.15 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 4)
    return x * adsr(n, 0.002, 0.05, 1.0, 0.05) * vel * 0.6


def marimba(f, dur, vel=0.8):
    n = int(1.0 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 5) + 0.3 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t * 14)
    x += 0.08 * RNG.standard_normal(n) * np.exp(-t * 120)
    return x * vel * 0.8


def bell(f, dur, vel=0.8, ratio=3.5, index=2.5, decay=1.6):
    """Cloche FM."""
    n = int(max(2.5, dur + 1.5) * SR)
    t = np.arange(n) / SR
    mod = index * np.exp(-t * 2.5) * np.sin(2 * np.pi * f * ratio * t)
    x = np.sin(2 * np.pi * f * t + mod) * np.exp(-t * decay)
    return x * adsr(n, 0.002, 0.05, 1.0, 0.1) * vel * 0.5


def flute(f, dur, vel=0.8):
    n = int((dur + 0.25) * SR)
    x = osc("sine", f, n, vib=0.006, vib_rate=5.0, vib_delay=0.25) + 0.18 * osc("sine", f * 2, n) + 0.06 * osc("sine", f * 3, n)
    breath = bp(RNG.standard_normal(n), f * 0.8, f * 2.5) * 0.12
    return (x + breath) * adsr(n, 0.06, 0.1, 0.85, 0.22) * vel * 0.55


def clarinet(f, dur, vel=0.8):
    n = int((dur + 0.2) * SR)
    x = osc("square", f, n, vib=0.003, vib_delay=0.4)
    x = lp(x, 2200)
    return x * adsr(n, 0.04, 0.1, 0.8, 0.18) * vel * 0.4


def brass(f, dur, vel=0.8, bright=0.7):
    """Cuivres : la brillance suit l'attaque (mélange sombre / brillant)."""
    n = int((dur + 0.3) * SR)
    x = sum(osc("saw", f, n, phase0=RNG.random(), detune=d, vib=0.003, vib_delay=0.35) for d in (-5, 0, 6)) / 3
    dark, brt = lp(x, 900 + f), lp(x, 3200 + bright * 4500)
    ev = np.clip(np.exp(-np.arange(n) / SR * 3.0) * 0.8 + 0.3 * bright, 0, 1)
    y = dark * (1 - ev) + brt * ev
    return y * adsr(n, 0.05, 0.25, 0.75, 0.28) * vel * 0.8


def choir(f, dur, vel=0.8, vowel="a"):
    """Chœur « aah / ooh » : scies filtrées par des formants."""
    n = int((dur + 0.6) * SR)
    x = sum(osc("saw", f, n, phase0=RNG.random(), detune=d, vib=0.005, vib_rate=4.6 + RNG.random()) for d in (-12, -4, 5, 13)) / 4
    forms = {"a": [(700, 1.0), (1220, 0.6), (2600, 0.25)], "o": [(450, 1.0), (800, 0.5), (2830, 0.15)]}[vowel]
    y = sum(peak(x, fr, 6.0) * g for fr, g in forms)
    return y * adsr(n, 0.35, 0.3, 0.9, 0.6) * vel * 1.4


def pad(f, dur, vel=0.8, bright=0.3):
    n = int((dur + 1.0) * SR)
    x = sum(osc("saw", f, n, phase0=RNG.random(), detune=d) for d in (-14, -6, 6, 14)) / 4
    x = lp(x, 800 + bright * 3500)
    return x * adsr(n, 0.8, 0.5, 0.9, 1.0) * vel * 0.7


def bass(f, dur, vel=0.8):
    n = int((dur + 0.15) * SR)
    x = osc("sine", f, n) * 0.35 + lp(osc("saw", f, n), 1400) * 0.7
    return x * adsr(n, 0.01, 0.2, 0.7, 0.12) * vel


def kalimba(f, dur, vel=0.8):
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 3.5) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 18)
    return x * adsr(n, 0.002, 0.03, 1.0, 0.05) * vel * 0.7


INSTRUMENTS = dict(strings=strings, pizz=pizz, harp=harp, celesta=celesta, marimba=marimba, bell=bell, flute=flute,
                   clarinet=clarinet, brass=brass, choir=choir, pad=pad, bass=bass, kalimba=kalimba)


# --- Percussions -----------------------------------------------------------------

def kick(vel=1.0):
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 45 + 90 * np.exp(-t * 30)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7) * 0.7
    x += bp(RNG.standard_normal(n), 1500, 5000) * np.exp(-t * 150) * 0.5
    return x * vel


def taiko(vel=1.0, pitch=1.0):
    n = int(1.2 * SR)
    t = np.arange(n) / SR
    f = (70 + 60 * np.exp(-t * 18)) * pitch
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5.0) * 0.55
    over = np.sin(2 * np.pi * np.cumsum(f * 2.7) / SR) * np.exp(-t * 9.0) * 0.35
    skin = bp(RNG.standard_normal(n), 180, 2200) * np.exp(-t * 16) * 0.9
    return (body + over + skin) * vel


def snare(vel=1.0):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = bp(RNG.standard_normal(n), 1500, 8000) * np.exp(-t * 18) * 0.7 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25) * 0.5
    return x * vel


def hat(vel=1.0, open_=False):
    n = int((0.35 if open_ else 0.08) * SR)
    t = np.arange(n) / SR
    return hp(RNG.standard_normal(n), 7000) * np.exp(-t * (8 if open_ else 60)) * vel * 0.5


def shaker(vel=1.0):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    e = np.minimum(t / 0.02, 1) * np.exp(-t * 30)
    return bp(RNG.standard_normal(n), 4000, 12000) * e * vel * 0.4


def tom(vel=1.0, f=110):
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    fr = f * (1 + 0.5 * np.exp(-t * 25))
    return (np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 7) * 0.7 + bp(RNG.standard_normal(n), 250, 3000) * np.exp(-t * 28) * 0.6) * vel


def timpani(vel=1.0, f=73.4):
    n = int(2.0 * SR)
    t = np.arange(n) / SR
    x = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * d) for r, a, d in [(1, 1.0, 1.6), (1.5, 0.5, 2.4), (1.98, 0.3, 3.0), (2.44, 0.15, 4.0)])
    x += bp(RNG.standard_normal(n), 150, 1500) * np.exp(-t * 20) * 0.6
    return x * vel * 0.8


def cymbal(vel=1.0, dur=2.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = hp(RNG.standard_normal(n), 3500) * np.exp(-t * 2.0) * np.minimum(t / 0.005, 1)
    return x * vel * 0.35


def frame_drum(vel=1.0):
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 140 * t) * np.exp(-t * 12) * 0.5 + bp(RNG.standard_normal(n), 400, 4000) * np.exp(-t * 30) * 0.7) * vel


DRUMS = dict(kick=kick, taiko=taiko, snare=snare, hat=hat, ohat=lambda v=1.0: hat(v, True), shaker=shaker, tom=tom,
             ltom=lambda v=1.0: tom(v, 75), timpani=timpani, cymbal=cymbal, frame=frame_drum)


# --- Effets -------------------------------------------------------------------

def reverb_ir(seconds=2.8, damp=0.5, predelay=0.02):
    """Réponse impulsionnelle stéréo synthétique (salle / caverne)."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    ir = np.zeros((2, n + int(predelay * SR)))
    for ch in range(2):
        noise = RNG.standard_normal(n) * np.exp(-t * (6.9 / seconds))
        noise = lp(noise, 9000 - damp * 6000)
        ir[ch, int(predelay * SR):] = noise
        for k in range(6):  # premières réflexions
            pos = int((0.008 + RNG.random() * 0.05) * SR)
            ir[ch, pos] += (0.6 - k * 0.08) * (1 if RNG.random() > 0.5 else -1)
    return ir / np.sqrt(np.sum(ir ** 2, axis=1, keepdims=True))


def reverb(x, wet=0.25, seconds=2.8, damp=0.5):
    """x : (2, n). Convolution FFT ; la queue est renvoyée en fin de tableau."""
    ir = reverb_ir(seconds, damp)
    y = np.stack([signal.fftconvolve(x[ch], ir[ch]) for ch in range(2)])
    out = np.zeros_like(y)
    out[:, :x.shape[1]] = x * (1 - wet * 0.5)
    return out + y * wet


def pan(mono, p=0.0):
    """p de -1 (gauche) à 1 (droite), loi à puissance constante."""
    a = (p + 1) * np.pi / 4
    return np.stack([mono * np.cos(a), mono * np.sin(a)])


def chorus(x, depth=0.003, rate=0.6):
    n = x.shape[-1]
    t = np.arange(n)
    out = np.empty_like(x)
    for ch in range(x.shape[0]):
        d = (depth * SR) * (1 + np.sin(2 * np.pi * rate * t / SR + ch * np.pi / 2)) / 2 + 0.008 * SR
        out[ch] = 0.6 * x[ch] + 0.4 * np.interp(t - d, t, x[ch])
    return out


def compress(x, thresh=0.35, ratio=3.0, attack=0.005, release=0.15):
    """Compresseur simple (enveloppe RMS lissée)."""
    lvl = np.sqrt(lp(np.max(np.abs(x), axis=0) ** 2, 20, 1).clip(1e-9))
    gain = np.ones_like(lvl)
    over = lvl > thresh
    gain[over] = (thresh + (lvl[over] - thresh) / ratio) / lvl[over]
    return x * gain


def master(x, target_peak=0.95, rms_target=0.13, air=0.5, low_cut=45):
    """Mastering : coupe-bas, air (aigus), niveau par la moyenne (RMS) puis
    limiteur doux ; les passages forts restent plus forts que les doux."""
    x = x - np.mean(x, axis=1, keepdims=True)
    x = hp(x, low_cut)
    x = x - lp(x, 150, 2) * 0.55          # moins de graves inaudibles sur téléphone
    x = x + bp(x, 1200, 4500, 1) * 0.25   # présence
    x = x + hp(x, 3500, 1) * air
    rms = np.sqrt(np.mean(x ** 2)) + 1e-9
    x = x * (rms_target / rms)
    knee = 0.6
    a = np.abs(x)
    over = a > knee
    x[over] = np.sign(x[over]) * (knee + (1 - knee) * np.tanh((a[over] - knee) / (1 - knee)))
    pk = np.max(np.abs(x))
    return x * (target_peak / pk) if pk > target_peak else x


# --- Piste et partition ---------------------------------------------------------

class Track:
    """Table de mixage : on y dépose des sons (mono ou stéréo) à un instant donné."""

    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.buf = np.zeros((2, self.n + 6 * SR))

    def add(self, sound, at, gain=1.0, pan_=0.0):
        if sound.ndim == 1:
            sound = pan(sound, pan_)
        i = max(0, int(at * SR))
        if i >= self.buf.shape[1]:
            return
        m = min(sound.shape[1], self.buf.shape[1] - i)
        self.buf[:, i:i + m] += sound[:, :m] * gain


class Song:
    """Partition à tempo fixe ; les temps sont en battements."""

    def __init__(self, bpm, bars, beats_per_bar=4):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bars = bars
        self.bpb = beats_per_bar
        self.length = bars * beats_per_bar * self.beat
        self.stems = {}

    def stem(self, name):
        if name not in self.stems:
            self.stems[name] = Track(self.length)
        return self.stems[name]

    def note(self, stem, inst, pitch, beat, beats, vel=0.8, pan_=0.0, **kw):
        f = hz(pitch) if not isinstance(pitch, float) else pitch
        snd = INSTRUMENTS[inst](f, beats * self.beat, vel, **kw)
        self.stem(stem).add(snd, beat * self.beat, 1.0, pan_)

    def chord(self, stem, inst, pitches, beat, beats, vel=0.6, spread=0.5, **kw):
        for i, p in enumerate(pitches):
            pn = (i / max(1, len(pitches) - 1) - 0.5) * 2 * spread if len(pitches) > 1 else 0.0
            self.note(stem, inst, p, beat, beats, vel / np.sqrt(len(pitches)), pn, **kw)

    def drum(self, stem, kind, beat, vel=1.0, pan_=0.0):
        self.stem(stem).add(DRUMS[kind](vel), beat * self.beat, 1.0, pan_)

    def render(self, mix, rev=0.25, rev_time=2.8, loop=True, tail=3.0):
        """mix : {stem: (gain, part_de_réverbération)}. Boucle sans couture : la
        queue de réverbération est ramenée au début du morceau."""
        n = int(self.length * SR)
        dry = np.zeros((2, n + 6 * SR))
        send = np.zeros_like(dry)
        for name, tr in self.stems.items():
            g, s = mix.get(name, (1.0, 0.3))
            dry += tr.buf * g
            send += tr.buf * g * s
        wet = reverb(send, 1.0, rev_time)[:, :dry.shape[1]]
        full = dry + wet * rev * 2.5
        if loop:
            out = full[:, :n].copy()
            extra = full[:, n:]
            m = min(extra.shape[1], n)
            out[:, :m] += extra[:, :m]
        else:
            out = full[:, :n + int(tail * SR)]
        return master(out)


def save_ogg(name, x, quality=6):
    """x : (2, n) ou (n,) dans [-1, 1]."""
    os.makedirs(OUT, exist_ok=True)
    if x.ndim == 1:
        x = np.stack([x, x])
    pcm = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    out = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", str(quality), out], check=True)
    os.unlink(path)
    return out
