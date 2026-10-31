"""Bande-son originale de HIGHVALE, entièrement synthétisée (numpy + ffmpeg).

    python3 tools/audio/make_audio.py

Produit assets/audio/*.ogg : musiques en boucle (cité, combat), jingles
(victoire, défaite) et effets sonores de l'interface et des combats.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(d * SR)) / SR


def note(n):
    """Numéro MIDI -> fréquence."""
    return 440.0 * 2 ** ((n - 69) / 12)


def env(d, a=0.01, dec=0.2, s=0.6, r=0.3):
    n = int(d * SR)
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(dec * SR), int(r * SR)
    if na:
        e[:na] = np.linspace(0, 1, na)
    if nd:
        e[na:na + nd] = np.linspace(1, s, len(e[na:na + nd]))
    if nr:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def pluck(f, d, bright=0.5):
    x = t(d)
    sig = np.sin(2 * np.pi * f * x) + bright * 0.5 * np.sin(4 * np.pi * f * x) + bright * 0.25 * np.sin(6 * np.pi * f * x)
    return sig * np.exp(-x * (3.0 + f / 400))


def bell(f, d):
    x = t(d)
    sig = sum(a * np.sin(2 * np.pi * f * m * x) for m, a in ((1, 1), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12)))
    return sig * np.exp(-x * 2.2)


def pad(freqs, d):
    x = t(d)
    sig = np.zeros_like(x)
    for f in freqs:
        for det in (-0.6, 0.0, 0.7):
            sig += np.sin(2 * np.pi * (f + det) * x + rng.uniform(0, 6.28))
    return sig / (len(freqs) * 3) * env(d, a=d * 0.3, dec=0.1, s=1.0, r=d * 0.35)


def noise(d):
    return rng.uniform(-1, 1, int(d * SR))


def lowpass(sig, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    out = np.zeros_like(sig)
    acc = 0.0
    for i, v in enumerate(sig):
        acc = (1 - a) * v + a * acc
        out[i] = acc
    return out


def reverb(sig, delays=(0.031, 0.047, 0.071, 0.113), fb=0.35, mix=0.3):
    out = sig.copy()
    for dl in delays:
        n = int(dl * SR)
        tail = np.zeros(len(sig) + n * 6)
        tail[:len(sig)] = sig
        for k in range(1, 6):
            tail[n * k:n * k + len(sig)] += sig * (fb ** k)
        out = out + mix / len(delays) * tail[:len(sig)]
    return out


def layer(*sigs):
    """Superpose des signaux de longueurs différentes."""
    out = np.zeros(max(len(x) for x in sigs))
    for x in sigs:
        out[:len(x)] += x
    return out


def mix_at(buf, sig, start, gain=1.0):
    i = int(start * SR)
    if i >= len(buf):
        return
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[:end - i] * gain


def kick(d=0.35):
    x = t(d)
    f = 50 + 120 * np.exp(-x * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x * 9)


def snare(d=0.25):
    x = t(d)
    return (lowpass(noise(d), 5000) * 0.8 + 0.3 * np.sin(2 * np.pi * 190 * x)) * np.exp(-x * 18)


def hat(d=0.06):
    return (noise(d) - lowpass(noise(d), 6000)) * np.exp(-t(d) * 60)


def save(name, sig, loop=False):
    sig = sig / max(1e-9, np.max(np.abs(sig))) * 0.89
    if not loop:
        fade = int(0.01 * SR)
        sig[-fade:] *= np.linspace(1, 0, fade)
    data = (sig * 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data.tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4",
                        os.path.join(OUT, name + ".ogg")], check=True)
    print(name, round(len(sig) / SR, 2), "s")


# --- Musiques ---------------------------------------------------------------

def city_theme():
    """Thème de la cité : nappes de ré dorien, harpe de cristal, carillons."""
    bpm = 84
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    buf = np.zeros(int(total * SR) + SR)
    chords = [[50, 57, 60, 64, 65], [46, 53, 57, 62, 65], [53, 57, 60, 64, 67], [48, 55, 60, 62, 67]]
    for bar in range(bars):
        ch = chords[bar % 4]
        mix_at(buf, pad([note(n) for n in ch[1:]], 4 * beat * 1.15), bar * 4 * beat, 0.5)
        mix_at(buf, pluck(note(ch[0] - 12), 4 * beat, 0.2), bar * 4 * beat, 0.5)
        pattern = [0, 2, 3, 4, 3, 2, 1, 2]
        for i, p in enumerate(pattern):
            mix_at(buf, pluck(note(ch[p] + 12), beat * 1.2, 0.6), bar * 4 * beat + i * beat / 2, 0.22)
        if bar % 2 == 1:
            for k in range(3):
                mix_at(buf, bell(note(ch[rng.integers(1, 5)] + 24), 2.5), bar * 4 * beat + rng.uniform(0, 3.5) * beat, 0.08)
    melody = [74, 72, 69, 67, 69, 72, 74, 76, 77, 76, 74, 72, 69, 72, 74, 74]
    for bar in range(8, 16):
        for k in range(2):
            n = melody[((bar - 8) * 2 + k) % len(melody)]
            mix_at(buf, bell(note(n), 2.0) * 0.8 + pluck(note(n), 2.0, 0.3), bar * 4 * beat + k * 2 * beat, 0.16)
    sig = reverb(buf[:int(total * SR)], mix=0.45)
    # Raccord de boucle : la queue de réverbération reboucle sur le début.
    tail = reverb(buf, mix=0.45)[int(total * SR):]
    sig[:len(tail)] += tail[:len(sig)]
    save("music_city", sig, loop=True)


def battle_theme():
    """Thème de combat : 132 BPM, la mineur, batterie, basse obstinée, arpèges."""
    bpm = 132
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    buf = np.zeros(int(total * SR) + SR)
    prog = [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59]]
    for bar in range(bars):
        ch = prog[bar % 4]
        s = bar * 4 * beat
        for b in range(4):
            mix_at(buf, kick(), s + b * beat, 0.9 if b % 2 == 0 else 0.6)
            if b % 2 == 1:
                mix_at(buf, snare(), s + b * beat, 0.55)
            for h in range(2):
                mix_at(buf, hat(), s + b * beat + h * beat / 2, 0.18)
        for e in range(8):
            bass = pluck(note(ch[0] - 24 + (12 if e % 4 == 3 else 0)), beat * 0.6, 0.9)
            mix_at(buf, np.tanh(bass * 2.5) * 0.6, s + e * beat / 2, 0.45)
        for e in range(16):
            mix_at(buf, pluck(note(ch[e % 3] + 12 + (12 if e % 8 >= 6 else 0)), beat * 0.5, 0.8), s + e * beat / 4, 0.13)
        mix_at(buf, pad([note(n) for n in ch], 4 * beat * 1.05), s, 0.3)
        if bar >= 8:
            lead = [69, 72, 76, 74, 72, 71, 72, 69][bar % 8]
            x = t(beat * 2)
            saw = sum(np.sin(2 * np.pi * note(lead) * k * x) / k for k in range(1, 6))
            mix_at(buf, saw * env(beat * 2, 0.02, 0.2, 0.7, 0.3), s, 0.12)
            mix_at(buf, saw * env(beat * 2, 0.02, 0.2, 0.7, 0.3), s + 2 * beat, 0.1)
    save("music_battle", reverb(buf[:int(total * SR)], mix=0.2), loop=True)


def jingle(name, notes, step, final_chord):
    total = len(notes) * step + 2.5
    buf = np.zeros(int(total * SR))
    for i, n in enumerate(notes):
        mix_at(buf, layer(pluck(note(n), 0.6, 0.7), 0.4 * bell(note(n + 12), 0.8)), i * step, 0.5)
    mix_at(buf, pad([note(n) for n in final_chord], 2.4), len(notes) * step, 0.9)
    for n in final_chord:
        mix_at(buf, bell(note(n + 12), 2.0), len(notes) * step, 0.2)
    save(name, reverb(buf, mix=0.4))


# --- Effets sonores -------------------------------------------------------------

def sfx():
    x = t(0.06)
    save("sfx_click", np.sin(2 * np.pi * 900 * x) * np.exp(-x * 70) + 0.4 * np.sin(2 * np.pi * 1800 * x) * np.exp(-x * 90))
    buf = np.zeros(int(0.7 * SR))
    for i, n in enumerate([84, 88, 91]):
        mix_at(buf, bell(note(n), 0.5), i * 0.06, 0.6)
    save("sfx_collect", buf)
    buf = np.zeros(int(0.8 * SR))
    for i in range(3):
        knock = lowpass(noise(0.12), 1800) * np.exp(-t(0.12) * 35) + 0.5 * np.sin(2 * np.pi * 220 * t(0.12)) * np.exp(-t(0.12) * 30)
        mix_at(buf, knock, i * 0.2, 0.9)
    save("sfx_build", buf)
    buf = np.zeros(int(1.6 * SR))
    for i, n in enumerate([72, 76, 79, 84, 88]):
        mix_at(buf, layer(pluck(note(n), 0.7, 0.7), 0.5 * bell(note(n + 12), 0.9)), i * 0.08, 0.5)
    for k in range(10):
        mix_at(buf, bell(note(96 + rng.integers(0, 8)), 0.4), 0.4 + k * 0.05, 0.08)
    save("sfx_levelup", reverb(buf, mix=0.35))
    buf = np.zeros(int(0.5 * SR))
    mix_at(buf, np.sin(2 * np.pi * 300 * t(0.08)) * np.exp(-t(0.08) * 40), 0, 0.8)
    mix_at(buf, bell(note(91), 0.4), 0.05, 0.5)
    save("sfx_harvest", buf)
    hit = lowpass(noise(0.18), 2500) * np.exp(-t(0.18) * 22) + kick(0.18) * 0.7
    save("sfx_hit", hit)
    crit = np.zeros(int(0.6 * SR))
    mix_at(crit, hit, 0, 1.0)
    mix_at(crit, bell(note(96), 0.5), 0.02, 0.6)
    save("sfx_crit", crit)
    buf = np.zeros(int(1.0 * SR))
    for i, n in enumerate([72, 76, 79, 83]):
        mix_at(buf, bell(note(n), 0.7), i * 0.07, 0.35)
    save("sfx_heal", reverb(buf, mix=0.4))
    d = 0.6
    sweep = noise(d) * np.sin(np.linspace(0, np.pi, int(d * SR)))
    save("sfx_magic", reverb(lowpass(sweep, 3500) + 0.3 * bell(note(88), d), mix=0.4))
    d = 2.2
    x = t(d)
    rise = np.sin(2 * np.pi * np.cumsum(200 + 900 * (x / d) ** 2) / SR) * (x / d) * 0.5 + lowpass(noise(d), 4000) * (x / d) ** 2 * 0.5
    save("sfx_charge", reverb(rise, mix=0.3))
    buf = np.zeros(int(3.0 * SR))
    mix_at(buf, kick(0.5), 0, 1.0)
    mix_at(buf, lowpass(noise(0.8), 6000) * np.exp(-t(0.8) * 6), 0, 0.6)
    for n in [60, 67, 72, 76, 79, 84]:
        mix_at(buf, bell(note(n), 2.5), 0.02, 0.25)
    mix_at(buf, pad([note(n) for n in [60, 64, 67, 72]], 2.6), 0, 0.8)
    save("sfx_reveal", reverb(buf, mix=0.5))
    x = t(0.25)
    save("sfx_error", np.sign(np.sin(2 * np.pi * 140 * x)) * 0.4 * np.exp(-x * 10))
    buf = np.zeros(int(0.5 * SR))
    mix_at(buf, lowpass(noise(0.4), 1200) * np.sin(np.linspace(0, np.pi, int(0.4 * SR))), 0, 0.8)
    save("sfx_whoosh", buf)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    city_theme()
    battle_theme()
    jingle("jingle_victory", [67, 72, 76, 79], 0.14, [60, 64, 67, 72, 76])
    jingle("jingle_defeat", [69, 67, 64, 60], 0.22, [57, 60, 64])
    sfx()
