"""Effets sonores de HIGHVALE, conçus par couches (attaque, corps, queue).

    python3 tools/audio/sfx.py [nom…]

Produit assets/audio/sfx_<nom>.ogg.
"""
import sys

import numpy as np

from synth import SR, RNG, hz, midi, lp, hp, bp, peak, save_ogg, reverb, pan, bell, harp, celesta, choir, strings, brass, timpani, cymbal


def T(d):
    return np.arange(int(d * SR)) / SR


def noise(d):
    return RNG.standard_normal(int(d * SR))


def env_exp(d, k, a=0.002):
    t = T(d)
    return np.minimum(t / max(a, 1e-4), 1) * np.exp(-t * k)


def sweep(f0, f1, d, kind="sine", curve=1.0):
    t = T(d)
    u = (t / d) ** curve
    f = f0 * (f1 / f0) ** u
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        return np.sin(ph)
    if kind == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    return np.sign(np.sin(ph))


def nsweep(d, f0, f1, width=1.5):
    """Bruit filtré dont la bande glisse de f0 à f1 (souffle, whoosh)."""
    x = noise(d)
    n = len(x)
    out = np.zeros(n)
    seg = 512
    for i in range(0, n, seg):
        u = i / n
        fc = f0 * (f1 / f0) ** u
        lo, hi = max(40, fc / width), min(SR / 2 - 100, fc * width)
        out[i:i + seg] = bp(x[i:i + seg + 2048], lo, hi, 1)[:len(out[i:i + seg])]
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, delay):
    return np.concatenate([np.zeros(int(delay * SR)), x])


def ping(f, d=0.3, k=12, ratio=2.76, idx=1.2):
    t = T(d)
    return np.sin(2 * np.pi * f * t + idx * np.exp(-t * 20) * np.sin(2 * np.pi * f * ratio * t)) * np.exp(-t * k)


def thump(f=90, d=0.3, k=14):
    t = T(d)
    fr = max(f, 95) * (1 + 1.5 * np.exp(-t * 40))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    # Sinus saturé : ses harmoniques gardent l'impact audible sur un petit haut-parleur.
    return (np.tanh(2.5 * np.sin(ph)) * 0.8 + 0.25 * np.sin(2 * ph)) * np.exp(-t * k)


def phone_level(st):
    """Niveau perçu sur un haut-parleur de téléphone : RMS maximal (fenêtres de
    50 ms) au-dessus de 300 Hz."""
    y = hp(st.mean(axis=0), 300, 4)
    w = int(0.05 * SR)
    m = len(y) // w
    if m == 0:
        return np.sqrt(np.mean(y ** 2)) + 1e-9
    return np.sqrt(np.max(np.mean(y[:m * w].reshape(m, w) ** 2, axis=1))) + 1e-9


def finish(x, stereo_width=0.25, rev=0.12, rev_time=1.2, gain=0.85, loud=-14.0):
    st = np.stack([x, np.roll(x, int(SR * 0.0007 * stereo_width * 10))])
    if rev:
        st = reverb(st, rev, rev_time)[:, :st.shape[1] + int(rev_time * SR * 0.6)]
    st = hp(st, 85)
    # Haut-parleurs de téléphone : on retire une partie du grave et on le
    # remplace par ses harmoniques (saturation douce), audibles sur petit HP.
    low = lp(st, 220, 2)
    norm = np.max(np.abs(low)) + 1e-9
    st = st - low * 0.6 + hp(np.tanh(low / norm * 3.0) * norm, 180, 2) * 0.55
    # Niveau homogène d'un effet à l'autre (cible en dB, mesurée côté téléphone),
    # puis limiteur doux.
    st = st * (10 ** (loud / 20) / phone_level(st))
    pk = np.max(np.abs(st))
    if pk > 0.95:
        st = np.tanh(st / pk * 1.5) / np.tanh(1.5) * 0.95
    # Coupe la fin silencieuse (sous -55 dB).
    lvl = np.max(np.abs(st), axis=0)
    loud_idx = np.nonzero(lvl > np.max(lvl) * 10 ** (-55 / 20))[0]
    if len(loud_idx):
        st = st[:, :min(st.shape[1], loud_idx[-1] + int(0.03 * SR))]
    fade = min(st.shape[1], int(0.02 * SR))
    st[:, -fade:] *= np.linspace(1, 0, fade)
    return st


# --- Interface --------------------------------------------------------------------
def click():
    return finish(mix(ping(1900, 0.05, 90, 1.5, 0.4) * 0.6, bp(noise(0.03), 2000, 7000) * env_exp(0.03, 200) * 0.5,
                      thump(260, 0.06, 60) * 0.5), rev=0.03, loud=-22)


def tab():
    return finish(mix(ping(2400, 0.06, 80, 1.5, 0.3) * 0.5, thump(340, 0.05, 70) * 0.4), rev=0.03, loud=-24)


def open_():
    return finish(mix(nsweep(0.32, 400, 3500) * env_exp(0.32, 6, 0.08) * 0.7, at(celesta(hz("A6"), 0.2, 0.4), 0.12) * 0.5,
                      at(celesta(hz("E7"), 0.2, 0.3), 0.18) * 0.35), rev=0.2)


def close():
    return finish(nsweep(0.25, 2800, 350) * env_exp(0.25, 9, 0.03), rev=0.08, loud=-20)


def error():
    t = T(0.28)
    x = (np.sign(np.sin(2 * np.pi * 247 * t)) * 0.5 + np.sin(2 * np.pi * 494 * t) * 0.4) * env_exp(0.28, 10)
    x[int(0.13 * SR):] += (np.sign(np.sin(2 * np.pi * 196 * t[:len(t) - int(0.13 * SR)])) * 0.5)[:len(x) - int(0.13 * SR)] * env_exp(0.28 - 0.13, 12)[:len(x) - int(0.13 * SR)]
    return finish(lp(x, 2200), rev=0.05, loud=-16)


def notify():
    return finish(mix(bell(hz("E6"), 0.4, 0.6), at(bell(hz("B6"), 0.4, 0.5), 0.12)), rev=0.2, gain=0.6)


# --- Cité, économie -------------------------------------------------------------------
def hammer(dt=0.0, metal=1.0):
    x = mix(thump(140, 0.18, 22) * 0.8, bp(noise(0.05), 800, 4000) * env_exp(0.05, 70) * 0.6,
            ping(2100 * RNG.uniform(0.95, 1.05), 0.25, 18, 2.4, 0.8) * 0.35 * metal)
    return at(x, dt)


def build():
    return finish(mix(hammer(0.0), hammer(0.22, 0.6), hammer(0.44, 1.2), at(nsweep(0.3, 300, 900) * env_exp(0.3, 12) * 0.3, 0.5)), rev=0.15)


def build_done():
    parts = [at(harp(hz(p), 0.4, 0.7), i * 0.07) for i, p in enumerate(("C5", "E5", "G5", "C6"))]
    parts.append(at(bell(hz("C7"), 0.6, 0.4), 0.3))
    parts.append(at(nsweep(0.4, 2000, 8000) * env_exp(0.4, 8, 0.05) * 0.25, 0.25))
    return finish(mix(*parts), rev=0.3, rev_time=1.6)


def upgrade():
    parts = [at(harp(hz(midi("D5") + iv), 0.4, 0.6), i * 0.045) for i, iv in enumerate((0, 2, 4, 7, 9, 12, 14, 16, 19, 24))]
    parts.append(nsweep(0.5, 300, 4000) * env_exp(0.5, 5, 0.2) * 0.35)
    parts.append(at(bell(hz("D7"), 0.8, 0.5), 0.45))
    parts.append(at(bell(hz("A7"), 0.8, 0.3), 0.5))
    return finish(mix(*parts), rev=0.3, rev_time=1.8)


def coin_ping(dt, f):
    return at(mix(ping(f, 0.35, 14, 2.92, 1.6) * 0.6, ping(f * 1.5, 0.2, 25, 2.1, 0.8) * 0.3), dt)


def collect():
    return finish(mix(*[coin_ping(i * 0.055 + RNG.uniform(0, 0.02), RNG.uniform(2600, 4200)) for i in range(7)]), rev=0.12)


def coin():
    return finish(coin_ping(0, 3300), rev=0.1, gain=0.6)


def collect_res():
    return finish(mix(thump(120, 0.2, 18), bp(noise(0.12), 300, 2500) * env_exp(0.12, 30) * 0.6,
                      at(ping(1500, 0.3, 14, 2.0, 0.5) * 0.3, 0.05)), rev=0.1)


def harvest():
    def hit_(dt):
        return at(mix(bp(noise(0.06), 1500, 7000) * env_exp(0.06, 60), ping(3100, 0.2, 25, 3.3, 1.0) * 0.5, thump(200, 0.1, 30) * 0.5), dt)
    return finish(mix(hit_(0), hit_(0.16), at(bell(hz("E7"), 0.4, 0.35, ratio=5.0, index=1.0), 0.3)), rev=0.2)


def purchase():
    parts = [coin_ping(0.03 * i + RNG.uniform(0, 0.015), RNG.uniform(2400, 4400)) for i in range(12)]
    parts.append(at(bell(hz("G6"), 0.6, 0.6), 0.35))
    parts.append(at(bell(hz("D7"), 0.6, 0.45), 0.42))
    return finish(mix(*parts), rev=0.2)


def chest():
    t = T(0.45)
    creak = (peak(noise(0.45), 380, 18) + peak(noise(0.45), 760, 18) * 0.5 + peak(noise(0.45), 1150, 12) * 0.3) * (np.sin(np.pi * t / 0.45) ** 2) * 0.5
    thud = at(mix(thump(110, 0.25, 16), bp(noise(0.08), 200, 1500) * env_exp(0.08, 40) * 0.5), 0.45)
    sparkle = [at(ping(RNG.uniform(3000, 6000), 0.4, 10, 2.5, 1.0) * 0.25, 0.55 + i * 0.04) for i in range(10)]
    swell = at(nsweep(0.6, 600, 6000) * env_exp(0.6, 5, 0.15) * 0.3, 0.5)
    return finish(mix(creak, thud, swell, *sparkle), rev=0.3, rev_time=1.6)


def feed():
    def bite(dt):
        return at(mix(bp(noise(0.07), 500, 3000) * env_exp(0.07, 45) * 0.8, thump(180, 0.07, 50) * 0.4), dt)
    chirp = at(sweep(900, 1500, 0.12) * env_exp(0.12, 14, 0.01) * 0.4, 0.45)
    return finish(mix(bite(0), bite(0.13), bite(0.26), chirp), rev=0.1)


def equip():
    return finish(mix(ping(2600, 0.3, 14, 2.6, 1.4) * 0.6, ping(3900, 0.25, 18, 1.7, 0.6) * 0.4,
                      bp(noise(0.03), 3000, 9000) * env_exp(0.03, 120) * 0.4), rev=0.12, gain=0.65)


def star_up():
    parts = [at(celesta(hz(midi("A5") + iv), 0.3, 0.6), i * 0.06) for i, iv in enumerate((0, 4, 7, 12, 16, 19, 24))]
    parts.append(nsweep(0.6, 1000, 9000) * env_exp(0.6, 5, 0.3) * 0.25)
    parts += [at(bell(hz(p), 0.8, 0.4), 0.42) for p in ("A6", "C#7", "E7")]
    return finish(mix(*parts), rev=0.3, rev_time=1.8)


def levelup():
    parts = [at(harp(hz(p), 0.4, 0.7), i * 0.06) for i, p in enumerate(("G5", "B5", "D6", "G6"))]
    parts.append(at(bell(hz("G7"), 0.6, 0.4), 0.25))
    return finish(mix(*parts), rev=0.25)


# --- Laboratoire, fusion, invocations ---------------------------------------------------
def lab_bubble():
    parts = []
    for _ in range(14):
        f0 = RNG.uniform(300, 900)
        parts.append(at(sweep(f0, f0 * 2.2, 0.06) * env_exp(0.06, 40, 0.005) * RNG.uniform(0.3, 0.6), RNG.uniform(0, 1.0)))
    return finish(mix(lp(noise(1.1), 600) * 0.08, *parts), rev=0.2)


def lab_start():
    t = T(1.4)
    hum = lp(sweep(60, 180, 1.4, "saw", 0.6) * np.minimum(t / 0.8, 1) * 0.3, 1200)
    clicks = [at(bp(noise(0.02), 2000, 8000) * env_exp(0.02, 200) * 0.4, 0.1 + i * 0.12) for i in range(9)]
    zap = at(bp(noise(0.3), 2000, 9000) * env_exp(0.3, 12) * 0.4 + sweep(1200, 3000, 0.3) * env_exp(0.3, 10) * 0.2, 1.1)
    return finish(mix(hum, zap, *clicks), rev=0.2)


def fusion():
    swirl = nsweep(1.2, 300, 5000) * np.sin(np.pi * T(1.2) / 1.2) * 0.5
    zaps = [at(bp(noise(0.08), 3000, 10000) * env_exp(0.08, 30) * 0.5 * np.sign(np.sin(2 * np.pi * 60 * T(0.08))), RNG.uniform(0.2, 1.1)) for _ in range(8)]
    boom = at(mix(thump(70, 0.6, 6), bp(noise(0.4), 100, 1500) * env_exp(0.4, 9) * 0.6), 1.15)
    chord_ = [at(bell(hz(p), 1.0, 0.35), 1.15) for p in ("E6", "G#6", "B6")]
    return finish(mix(swirl, boom, *zaps, *chord_), rev=0.3, rev_time=2.0)


def summon():
    swell = nsweep(1.4, 200, 6000, 1.3) * (T(1.4) / 1.4) ** 2 * 0.6
    voices = [at(choir(hz(p), 1.2, 0.35), 0.2) * 0.6 for p in ("D4", "A4", "D5", "F#5")]
    hit_ = at(mix(thump(60, 0.8, 5) * 0.8, cymbal(0.6, 1.5)), 1.35)
    return finish(mix(swell, hit_, *voices), rev=0.35, rev_time=2.4)


def hatch():
    cracks = []
    dt = 0.05
    for _ in range(6):
        cracks.append(at(bp(noise(0.03), 1500, 8000) * env_exp(0.03, 90) * RNG.uniform(0.4, 0.8), dt))
        dt += RNG.uniform(0.05, 0.12)
    pop = at(thump(300, 0.12, 30) * 0.6, dt)
    chirp = at(mix(sweep(1200, 2200, 0.1) * env_exp(0.1, 12, 0.005), at(sweep(1400, 2600, 0.1) * env_exp(0.1, 12, 0.005), 0.14)) * 0.4, dt + 0.1)
    return finish(mix(pop, chirp, *cracks), rev=0.15)


def reveal():
    parts = [at(harp(hz(p), 0.4, 0.6), i * 0.05) for i, p in enumerate(("D5", "F#5", "A5", "D6", "F#6"))]
    parts.append(at(bell(hz("D7"), 0.8, 0.5), 0.28))
    return finish(mix(*parts), rev=0.3)


def magic():
    parts = [at(ping(RNG.uniform(2500, 7000), 0.4, 9, 2.5, 1.0) * 0.4, RNG.uniform(0, 0.35)) for _ in range(12)]
    parts.append(nsweep(0.5, 1500, 8000) * env_exp(0.5, 6, 0.08) * 0.3)
    return finish(mix(*parts), rev=0.3)


def whoosh():
    return finish(nsweep(0.35, 400, 2500, 1.8) * np.sin(np.pi * T(0.35) / 0.35) ** 2, rev=0.05, gain=0.7)


def charge():
    t = T(0.9)
    whine = lp(sweep(300, 1600, 0.9, "saw", 0.7) * (t / 0.9) * 0.25, 4000)
    air = nsweep(0.9, 500, 6000) * (t / 0.9) ** 1.5 * 0.4
    return finish(mix(whine, air), rev=0.15)


# --- Combat ------------------------------------------------------------------------------
def hit():
    return finish(mix(thump(110, 0.2, 20), bp(noise(0.1), 800, 6000) * env_exp(0.1, 45) * 0.7,
                      bp(noise(0.03), 3000, 10000) * env_exp(0.03, 150) * 0.5), rev=0.06, gain=0.8)


def hit_heavy():
    return finish(mix(thump(70, 0.45, 9) * 1.1, bp(noise(0.25), 150, 2500) * env_exp(0.25, 16) * 0.8,
                      bp(noise(0.04), 2500, 9000) * env_exp(0.04, 100) * 0.6,
                      at(bp(noise(0.3), 1000, 5000) * env_exp(0.3, 12) * 0.2, 0.08)), rev=0.12, gain=0.9)


def crit():
    return finish(mix(thump(90, 0.3, 14), bp(noise(0.12), 1000, 8000) * env_exp(0.12, 35) * 0.7,
                      ping(1800, 0.6, 6, 2.76, 2.0) * 0.4, ping(2700, 0.5, 8, 1.5, 1.0) * 0.3,
                      at(nsweep(0.2, 6000, 2000) * env_exp(0.2, 12) * 0.3, 0.02)), rev=0.15, gain=0.9)


def slash():
    sw = nsweep(0.18, 1500, 6000, 1.6) * np.sin(np.pi * T(0.18) / 0.18) * 0.6
    return finish(mix(sw, at(ping(3600, 0.3, 14, 2.3, 1.0) * 0.35, 0.12), at(thump(150, 0.12, 30) * 0.5, 0.14)), rev=0.08)


def fire():
    t = T(0.8)
    roar = bp(noise(0.8), 150, 2500) * np.minimum(t / 0.05, 1) * np.exp(-t * 3.5) * 0.7
    crackle = [at(bp(noise(0.015), 2000, 9000) * env_exp(0.015, 200) * RNG.uniform(0.2, 0.6), RNG.uniform(0.05, 0.7)) for _ in range(25)]
    return finish(mix(roar, nsweep(0.4, 300, 2000) * env_exp(0.4, 6, 0.05) * 0.5, *crackle), rev=0.15)


def ice():
    shards = [at(ping(RNG.uniform(3000, 7500), 0.5, 8, 3.1, 1.5) * 0.35, RNG.uniform(0, 0.15)) for _ in range(10)]
    crack = bp(noise(0.12), 2500, 10000) * env_exp(0.12, 40) * 0.7
    return finish(mix(crack, thump(250, 0.1, 30) * 0.4, *shards), rev=0.25)


def thunder():
    t = T(1.0)
    zap = bp(noise(0.25), 1500, 9000) * env_exp(0.25, 14) * np.abs(np.sign(np.sin(2 * np.pi * 37 * T(0.25)))) * 0.8
    rumble = lp(noise(1.0), 160) * np.minimum(t / 0.05, 1) * np.exp(-t * 3) * 2.5
    return finish(mix(zap, rumble, thump(60, 0.5, 7) * 0.5), rev=0.2, gain=0.9)


def water():
    splash = nsweep(0.4, 3000, 600) * env_exp(0.4, 8, 0.005) * 0.6
    bubbles = [at(sweep(f, f * 1.8, 0.05) * env_exp(0.05, 40, 0.004) * 0.3, RNG.uniform(0.05, 0.5)) for f in RNG.uniform(400, 1200, 12)]
    return finish(mix(splash, thump(140, 0.15, 25) * 0.4, *bubbles), rev=0.2)


def earth():
    t = T(0.8)
    rumble = lp(noise(0.8), 250) * np.exp(-t * 4) * 2.0
    rocks = [at(mix(thump(RNG.uniform(120, 260), 0.1, 35) * 0.5, bp(noise(0.03), 600, 3500) * env_exp(0.03, 80) * 0.5), RNG.uniform(0.02, 0.6)) for _ in range(10)]
    return finish(mix(rumble, thump(60, 0.5, 6) * 0.7, *rocks), rev=0.15, gain=0.9)


def wind():
    return finish(nsweep(0.7, 300, 3000, 2.0) * np.sin(np.pi * T(0.7) / 0.7) ** 1.5 * 0.8, rev=0.2)


def nature():
    rustle = bp(noise(0.5), 2500, 9000) * np.abs(np.sin(2 * np.pi * 11 * T(0.5))) * env_exp(0.5, 5, 0.05) * 0.4
    plucks = [at(harp(hz(p), 0.3, 0.4), 0.1 + i * 0.07) for i, p in enumerate(("E5", "G5", "B5"))]
    return finish(mix(rustle, thump(170, 0.12, 25) * 0.4, *plucks), rev=0.2)


def light():
    shimmer = [at(bell(hz(midi("A6") + iv), 0.6, 0.35, ratio=4.0, index=1.0), i * 0.04) for i, iv in enumerate((0, 4, 7, 12, 16))]
    return finish(mix(nsweep(0.6, 2000, 9000) * env_exp(0.6, 5, 0.1) * 0.3, *shimmer), rev=0.35, rev_time=1.8)


def shadow():
    d = 0.7
    t = T(d)
    swoosh = nsweep(d, 300, 1800, 1.6) * (t / d) ** 2 * 0.7
    low = sweep(140, 70, d) * np.sin(np.pi * t / d) * 0.5
    return finish(mix(swoosh, low, at(thump(80, 0.3, 12) * 0.6, d - 0.05)), rev=0.25)


def void():
    d = 0.8
    t = T(d)
    warp = lp(sweep(900, 80, d, "saw", 0.5) * np.sin(np.pi * t / d) * 0.3, 2500)
    wob = bp(noise(d), 200, 2000) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t)) * np.sin(np.pi * t / d) * 0.5
    return finish(mix(warp, wob), rev=0.3)


def heal():
    parts = [at(celesta(hz(p), 0.4, 0.55), i * 0.08) for i, p in enumerate(("C6", "E6", "G6", "C7"))]
    parts.append(nsweep(0.8, 800, 6000) * env_exp(0.8, 4, 0.2) * 0.2)
    return finish(mix(*parts), rev=0.35, rev_time=1.8)


def shield():
    t = T(0.6)
    hum = (np.sin(2 * np.pi * 220 * t) + 0.5 * np.sin(2 * np.pi * 331 * t) + 0.3 * np.sin(2 * np.pi * 447 * t)) * np.minimum(t / 0.03, 1) * np.exp(-t * 5)
    return finish(mix(hum * (1 + 0.3 * np.sin(2 * np.pi * 14 * t)) * 0.5, ping(2200, 0.5, 8, 2.0, 1.2) * 0.3), rev=0.25)


def buff():
    return finish(mix(*[at(ping(hz(midi("C6") + iv), 0.2, 16, 2.0, 0.6) * 0.5, i * 0.05) for i, iv in enumerate((0, 4, 7, 12))]), rev=0.2)


def debuff():
    d = 0.5
    t = T(d)
    return finish(sweep(700, 250, d) * (1 + 0.4 * np.sin(2 * np.pi * 12 * t)) * env_exp(d, 4, 0.02) * 0.6, rev=0.2)


def ko():
    fall = sweep(500, 120, 0.5) * env_exp(0.5, 5, 0.01) * 0.4
    thud = at(mix(thump(80, 0.4, 10), bp(noise(0.15), 150, 1500) * env_exp(0.15, 20) * 0.5), 0.45)
    return finish(mix(fall, thud), rev=0.2)


SFX = dict(click=click, tab=tab, open=open_, close=close, error=error, notify=notify, build=build, build_done=build_done,
           upgrade=upgrade, collect=collect, coin=coin, collect_res=collect_res, harvest=harvest, purchase=purchase,
           chest=chest, feed=feed, equip=equip, star_up=star_up, levelup=levelup, lab_bubble=lab_bubble,
           lab_start=lab_start, fusion=fusion, summon=summon, hatch=hatch, reveal=reveal, magic=magic,
           whoosh=whoosh, charge=charge, hit=hit, hit_heavy=hit_heavy, crit=crit, slash=slash, fire=fire,
           ice=ice, thunder=thunder, water=water, earth=earth, wind=wind, nature=nature, light=light,
           shadow=shadow, void=void, heal=heal, shield=shield, buff=buff, debuff=debuff, ko=ko)

if __name__ == "__main__":
    for name in sys.argv[1:] or list(SFX):
        x = SFX[name]()
        save_ogg("sfx_" + name, x, quality=6)
        print("%-12s %5.2f s" % (name, x.shape[1] / SR))
