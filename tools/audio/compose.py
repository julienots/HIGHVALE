"""Bande originale de HIGHVALE. Tous les morceaux partagent un même thème
(le « motif de HIGHVALE ») décliné selon l'ambiance.

    python3 tools/audio/compose.py [nom…]

Morceaux : music_menu, music_city, music_battle, music_boss, music_mystic,
music_shop, music_explore, amb_cave ; jingles : jingle_victory,
jingle_defeat, jingle_levelup, jingle_quest, jingle_reveal_0..3.
"""
import sys

import numpy as np

from synth import (SR, RNG, Song, Track, hz, midi, save_ogg, master, reverb, pan, lp, hp, bp,
                   harp, bell, celesta, brass, strings, choir, timpani, cymbal, taiko, pad)

QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "sus2": [0, 2, 7],
        "sus4": [0, 5, 7], "add9": [0, 4, 7, 14], "madd9": [0, 3, 7, 14], "m9": [0, 3, 7, 10, 14], "dim": [0, 3, 6],
        "7sus": [0, 5, 7, 10], "5": [0, 7, 12]}


def chord(sym, octave=3):
    root = sym[0]
    i = 1
    while i < len(sym) and sym[i] in "#b":
        root += sym[i]
        i += 1
    base = midi(root + str(octave))
    return [base + iv for iv in QUAL[sym[i:]]]


def hum(beat, amount=0.012):
    return beat + RNG.uniform(-amount, amount)


def melody(s, stem, inst, start, notes, vel=0.8, pan_=0.0, octave_shift=0, **kw):
    b = start
    for p, d in notes:
        if p is not None:
            m = midi(p) + 12 * octave_shift
            s.note(stem, inst, m, hum(b), d * 0.98, vel * RNG.uniform(0.92, 1.05), pan_, **kw)
        b += d
    return b


def arp(s, stem, inst, sym, start, beats, octave=4, step=0.5, pattern=(0, 1, 2, 3, 2, 1), vel=0.5, pan_=0.0, **kw):
    notes = chord(sym, octave)
    notes = notes + [n + 12 for n in notes]
    k = 0
    b = start
    while b < start + beats - 1e-6:
        s.note(stem, inst, notes[pattern[k % len(pattern)] % len(notes)], hum(b, 0.006), step * 1.5,
               vel * (1.0 if k % 2 == 0 else 0.8), pan_ + 0.3 * np.sin(k), **kw)
        k += 1
        b += step


def pads(s, stem, inst, prog, start, beats_each=4, octave=3, vel=0.5, **kw):
    for i, sym in enumerate(prog):
        s.chord(stem, inst, chord(sym, octave), start + i * beats_each, beats_each, vel, **kw)


def bassline(s, stem, prog, start, beats_each=4, pattern=((0, 2), (2, 2)), octave=2, inst="bass", vel=0.7, **kw):
    for i, sym in enumerate(prog):
        r = chord(sym, octave)[0]
        for off, d in pattern:
            s.note(stem, inst, r, hum(start + i * beats_each + off), d * 0.95, vel, 0.0, **kw)


# ======================================================================
# Le motif de HIGHVALE (ré mineur)
# ======================================================================
THEME_A = [("D5", 1.5), ("E5", .5), ("F5", 1), ("A5", 1),
           ("G5", 1.5), ("F5", .5), ("D5", 2),
           ("C5", 1), ("F5", 1), ("A5", 1), ("C6", 1),
           ("Bb5", 1.5), ("A5", .5), ("G5", 2),
           ("A5", 1.5), ("G5", .5), ("F5", 1), ("E5", 1),
           ("D5", 1), ("F5", 1), ("Bb5", 2),
           ("A5", 1), ("G5", 1), ("F5", 1), ("E5", 1),
           ("E5", 2), ("C#5", 1), ("A4", 1)]
PROG_A = ["Dm", "Bb", "F", "C", "Dm", "Bb", "Gm", "A"]
THEME_B = [("C6", 2), ("A5", 1), ("F5", 1),
           ("G5", 1.5), ("A5", .5), ("G5", 1), ("E5", 1),
           ("F5", 1.5), ("E5", .5), ("D5", 1), ("A5", 1),
           ("Bb5", 3), ("A5", 1),
           ("C6", 1), ("D6", 1), ("C6", 1), ("A5", 1),
           ("G5", 1), ("E5", 1), ("C5", 1), ("E5", 1),
           ("F5", 1), ("G5", 1), ("A5", 1), ("Bb5", 1),
           ("A5", 3), (None, 1)]
PROG_B = ["F", "C", "Dm", "Bb", "F", "C", "Bb", "A"]


def music_menu():
    """Thème principal : ouverture orchestrale (harpe, flûte, cors, chœur, timbales)."""
    s = Song(84, 36)
    intro = ["Dm", "Bb", "F", "C"]
    pads(s, "pad", "pad", intro, 0, octave=3, vel=0.5, bright=0.2)
    for i, c in enumerate(intro):
        arp(s, "harp", "harp", c, i * 4, 4, octave=4, step=0.5, vel=0.45)
    s.chord("choir", "choir", chord("Dm", 4), 8, 8, 0.3, vowel="o")
    for k in range(8):
        s.drum("perc", "timpani", 15 + k * 0.125, 0.15 + k * 0.06)
    # A : flûte, harpe et cordes
    a0 = 16
    melody(s, "lead", "flute", a0, THEME_A, 0.85)
    pads(s, "strings", "strings", PROG_A, a0, octave=3, vel=0.45, bright=0.4)
    for i, c in enumerate(PROG_A):
        arp(s, "harp", "harp", c, a0 + i * 4, 4, octave=4, step=0.5, vel=0.4)
    bassline(s, "bass", PROG_A, a0, pattern=((0, 3), (3, 1)), inst="strings", octave=2, vel=0.35, bright=0.2)
    # A' : cors + contrechant des cordes, chœur, timbales
    a1 = a0 + 32
    melody(s, "lead", "brass", a1, THEME_A, 0.8, octave_shift=-1)
    melody(s, "lead2", "strings", a1, THEME_A, 0.45, pan_=0.3)
    pads(s, "choir", "choir", PROG_A, a1, octave=3, vel=0.45, vowel="a")
    pads(s, "strings", "strings", PROG_A, a1, octave=3, vel=0.4, bright=0.5)
    bassline(s, "bass", PROG_A, a1, pattern=((0, 2), (2, 1), (3, 1)), inst="strings", octave=2, vel=0.5)
    for b in range(8):
        s.drum("perc", "timpani", a1 + b * 4, 0.7)
        s.drum("perc", "timpani", a1 + b * 4 + 2.5, 0.35)
    s.drum("perc", "cymbal", a1 + 31, 0.5)
    # B : apogée
    b0 = a1 + 32
    melody(s, "lead", "strings", b0, THEME_B, 0.8, bright=0.8)
    melody(s, "lead2", "brass", b0, THEME_B, 0.6, octave_shift=-1, pan_=-0.25)
    pads(s, "choir", "choir", PROG_B, b0, octave=3, vel=0.55, vowel="a")
    pads(s, "strings", "strings", PROG_B, b0, octave=3, vel=0.45, bright=0.6)
    bassline(s, "bass", PROG_B, b0, pattern=((0, 1), (1, 1), (2, 1), (3, 1)), inst="strings", octave=2, vel=0.5)
    for i, c in enumerate(PROG_B):
        arp(s, "harp", "harp", c, b0 + i * 4, 4, octave=5, step=0.25, pattern=(0, 1, 2, 3, 4, 5), vel=0.25)
        s.drum("perc", "taiko", b0 + i * 4, 0.8)
        s.drum("perc", "timpani", b0 + i * 4 + 2, 0.5)
    s.drum("perc", "cymbal", b0, 0.7)
    # Pont : célesta
    p0 = b0 + 32
    melody(s, "lead", "celesta", p0, THEME_A[:8], 0.7)
    pads(s, "pad", "pad", ["Dm", "Bb", "Dm", "A"], p0, octave=3, vel=0.5, bright=0.25)
    # Fin (retour à l'introduction pour la boucle)
    e0 = p0 + 16
    pads(s, "pad", "pad", ["Dm", "Bb", "Gm", "A"], e0, octave=3, vel=0.45, bright=0.2)
    for i, c in enumerate(["Dm", "Bb", "Gm", "A"]):
        arp(s, "harp", "harp", c, e0 + i * 4, 4, octave=4, step=0.5, vel=0.4)
    return s.render({"pad": (0.6, 0.5), "harp": (0.55, 0.35), "lead": (0.75, 0.3), "lead2": (0.45, 0.35), "strings": (0.5, 0.45),
                     "choir": (0.4, 0.6), "bass": (0.6, 0.2), "perc": (0.8, 0.3)}, rev=0.3, rev_time=3.2)


# ======================================================================
CITY_A = [("A4", 1), ("C5", 1), ("F5", 1.5), ("E5", .5), ("E5", 2), ("C5", 1), ("A4", 1),
          ("D5", 1), ("F5", 1), ("Bb5", 1.5), ("A5", .5), ("G5", 3), (None, 1),
          ("A5", 1), ("G5", .5), ("F5", .5), ("C5", 1), ("F5", 1), ("E5", 1.5), ("D5", .5), ("C5", 2),
          ("D5", 1), ("E5", 1), ("F5", 1), ("G5", 1), ("E5", 2), ("C5", 2)]
CITY_PA = ["F", "Am", "Bb", "C", "F", "Am", "Bb", "C"]
CITY_B = [("F5", 1.5), ("E5", .5), ("D5", 1), ("A5", 1), ("Bb5", 2), ("A5", 1), ("G5", 1),
          ("A5", 1), ("C6", 1), ("A5", 1), ("F5", 1), ("G5", 3), ("E5", 1),
          ("D5", 1), ("G5", 1), ("Bb5", 1), ("A5", 1), ("G5", 1), ("F5", 1), ("D5", 2),
          ("E5", 1), ("F5", 1), ("G5", 1), ("C6", 1), ("C6", 3), (None, 1)]
CITY_PB = ["Dm", "Bb", "F", "C", "Gm", "Bb", "C", "C"]


def music_city():
    """Les rues de HIGHVALE : harpe, kalimba, flûte, marimba, pizzicati, shaker."""
    s = Song(96, 40)

    def groove(start, prog, perc=True):
        for i, c in enumerate(prog):
            b = start + i * 4
            arp(s, "arp", "kalimba", c, b, 4, octave=4, step=0.5, pattern=(0, 2, 1, 3, 2, 1, 0, 2), vel=0.38, pan_=-0.2)
            r = chord(c, 2)[0]
            for off in (0, 1.5, 2.5):
                s.note("bass", "marimba", r + (7 if off == 1.5 else 0) + 12, hum(b + off), 0.5, 0.5)
            for off in (1, 3):
                s.chord("pizz", "pizz", chord(c, 4)[:3], hum(b + off), 0.5, 0.35, spread=0.6)
            if perc:
                for k in range(8):
                    s.drum("perc", "shaker", b + k * 0.5, 0.35 if k % 2 else 0.55, 0.3)
                s.drum("perc", "frame", b, 0.5)
                s.drum("perc", "frame", b + 2.5, 0.3)
        pads(s, "pad", "pad", prog, start, octave=3, vel=0.32, bright=0.3)

    groove(0, ["F", "Am", "Bb", "C"], perc=False)
    groove(16, CITY_PA)
    melody(s, "lead", "flute", 16, CITY_A, 0.8)
    groove(48, CITY_PB)
    melody(s, "lead", "flute", 48, CITY_B, 0.8)
    melody(s, "lead2", "harp", 48, CITY_B, 0.35, octave_shift=-1, pan_=0.4)
    groove(80, CITY_PA)
    melody(s, "lead", "clarinet", 80, CITY_A, 0.75)
    for i, c in enumerate(CITY_PA):
        arp(s, "lead2", "harp", c, 80 + i * 4, 4, octave=5, step=0.25, pattern=(0, 1, 2, 3), vel=0.2, pan_=0.4)
    groove(112, CITY_PB)
    melody(s, "lead", "strings", 112, CITY_B, 0.6, bright=0.5)
    melody(s, "lead2", "flute", 112, CITY_B, 0.55, octave_shift=1, pan_=0.3)
    groove(144, ["F", "Am", "Bb", "C"], perc=False)
    melody(s, "lead", "celesta", 144, CITY_A[:8], 0.55)
    return s.render({"arp": (0.55, 0.35), "bass": (0.6, 0.2), "pizz": (0.45, 0.3), "perc": (0.5, 0.2), "pad": (0.45, 0.5),
                     "lead": (0.75, 0.35), "lead2": (0.45, 0.4)}, rev=0.28, rev_time=2.6)


# ======================================================================
BAT_A = [("D5", 1.5), ("A4", .5), ("D5", 1), ("E5", 1), ("F5", 2), ("E5", 1), ("D5", 1),
         ("F5", 1.5), ("G5", .5), ("A5", 1), ("F5", 1), ("G5", 3), ("C5", 1),
         ("D5", 1.5), ("A4", .5), ("D5", 1), ("F5", 1), ("A5", 2), ("G5", 1), ("F5", 1),
         ("G5", 1), ("Bb5", 1), ("A5", 1), ("G5", 1), ("A5", 3), (None, 1)]
BAT_PA = ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Gm", "A"]
BAT_B = [("D6", 2), ("C6", 1), ("Bb5", 1), ("C6", 2), ("Bb5", 1), ("A5", 1),
         ("A5", 1.5), ("G5", .5), ("F5", 1), ("A5", 1), ("D6", 4),
         ("Bb5", 2), ("A5", 1), ("G5", 1), ("F5", 2), ("G5", 1), ("A5", 1),
         ("E5", 2), ("G5", 1), ("C#6", 1), ("A5", 4)]
BAT_PB = ["Bb", "C", "Dm", "Dm", "Gm", "Bb", "A", "A"]


def _ostinato(s, start, prog, vel=0.5, octave=3):
    for i, c in enumerate(prog):
        r = chord(c, octave)[0]
        for k, iv in enumerate([0, 0, 12, 0, 7, 0, 12, 7]):
            s.note("ost", "pizz", r + iv, hum(start + i * 4 + k * 0.5, 0.004), 0.4, vel * (1.0 if k % 2 == 0 else 0.75), 0.25)


def _war_drums(s, start, bars, heavy=False):
    for b in range(bars):
        x = start + b * 4
        s.drum("drums", "taiko", x, 1.0)
        s.drum("drums", "taiko", x + 1.5, 0.6, -0.3)
        s.drum("drums", "taiko", x + 2, 0.85)
        s.drum("drums", "tom", x + 3, 0.5, 0.3)
        s.drum("drums", "tom", x + 3.5, 0.6, 0.3)
        for k in range(8):
            s.drum("drums", "frame", x + k * 0.5, 0.25 if k % 2 else 0.35, 0.4)
        if heavy:
            s.drum("drums", "snare", x + 1, 0.5)
            s.drum("drums", "snare", x + 3, 0.6)
        if b % 4 == 3:
            for k in range(4):
                s.drum("drums", "ltom", x + 3 + k * 0.25, 0.4 + k * 0.15)


def music_battle():
    """Le choc des profondeurs : taikos, ostinato de cordes, cuivres héroïques."""
    s = Song(138, 32)
    _ostinato(s, 0, ["Dm", "Dm", "Bb", "C"], 0.45)
    _war_drums(s, 0, 4)
    a0 = 16
    _ostinato(s, a0, BAT_PA)
    _war_drums(s, a0, 8)
    melody(s, "lead", "brass", a0, BAT_A, 0.8, octave_shift=-1)
    pads(s, "str", "strings", BAT_PA, a0, octave=3, vel=0.35, bright=0.5)
    bassline(s, "bass", BAT_PA, a0, pattern=((0, .5), (.5, .5), (1, .5), (1.5, .5), (2, .5), (2.5, .5), (3, .5), (3.5, .5)), vel=0.45)
    a1 = a0 + 32
    _ostinato(s, a1, BAT_PA)
    _war_drums(s, a1, 8, heavy=True)
    melody(s, "lead", "strings", a1, BAT_A, 0.8, bright=0.9)
    melody(s, "lead2", "brass", a1, BAT_A, 0.55, octave_shift=-1, pan_=-0.3)
    pads(s, "choir", "choir", BAT_PA, a1, octave=3, vel=0.45)
    bassline(s, "bass", BAT_PA, a1, pattern=((0, .5), (.5, .5), (1, .5), (1.5, .5), (2, .5), (2.5, .5), (3, .5), (3.5, .5)), vel=0.5)
    s.drum("drums", "cymbal", a1, 0.6)
    b0 = a1 + 32
    _ostinato(s, b0, BAT_PB, 0.55)
    _war_drums(s, b0, 8, heavy=True)
    melody(s, "lead", "brass", b0, BAT_B, 0.85, octave_shift=-1)
    melody(s, "lead2", "strings", b0, BAT_B, 0.6, bright=0.9, pan_=0.3)
    pads(s, "choir", "choir", BAT_PB, b0, octave=3, vel=0.55)
    bassline(s, "bass", BAT_PB, b0, pattern=((0, .5), (.5, .5), (1, .5), (1.5, .5), (2, .5), (2.5, .5), (3, .5), (3.5, .5)), vel=0.5)
    s.drum("drums", "cymbal", b0, 0.7)
    d0 = b0 + 32
    _war_drums(s, d0, 4, heavy=True)
    for i, c in enumerate(["Dm", "Bb", "Gm", "A"]):
        s.chord("lead2", "brass", chord(c, 3)[:2], d0 + i * 4, 1.0, 0.7)
        s.chord("lead2", "brass", chord(c, 3)[:2], d0 + i * 4 + 1.5, 0.5, 0.6)
    _ostinato(s, d0, ["Dm", "Bb", "Gm", "A"], 0.4)
    return s.render({"ost": (0.6, 0.25), "drums": (0.55, 0.25), "lead": (0.8, 0.3), "lead2": (0.55, 0.3), "str": (0.45, 0.4),
                     "choir": (0.45, 0.5), "bass": (0.35, 0.15)}, rev=0.22, rev_time=2.2)


# ======================================================================
def music_boss():
    """Le Gardien : do mineur, chœur sombre, cuivres graves, seconde bémol menaçante."""
    s = Song(150, 32)
    prog = ["Cm", "Cm", "Db", "Db", "Cm", "Cm", "Ab", "G"]
    progb = ["Fm", "Ab", "Cm", "G", "Fm", "Db", "G", "G"]
    riff = [("C4", .5), ("C4", .5), ("Eb4", .5), ("C4", .5), ("G4", .5), ("C4", .5), ("Ab4", .5), ("G4", .5)]
    theme = [("C5", 2), ("Eb5", 1), ("D5", 1), ("Db5", 3), ("C5", 1), ("G4", 2), ("Ab4", 1), ("Bb4", 1), ("C5", 4),
             ("Eb5", 2), ("F5", 1), ("G5", 1), ("Ab5", 3), ("G5", 1), ("F5", 2), ("Eb5", 1), ("D5", 1), ("G4", 4)]
    for sec, pr in ((0, prog), (32, prog), (64, progb), (96, prog)):
        for i, c in enumerate(pr):
            b = sec + i * 4
            tr = chord(c, 3)[0] - midi("C3")
            for k, (p, d) in enumerate(riff):
                s.note("riff", "pizz", midi(p) + tr - 12, hum(b + k * 0.5, 0.004), 0.45, 0.6, -0.2)
                s.note("riff", "strings", midi(p) + tr, hum(b + k * 0.5, 0.004), 0.4, 0.25, 0.2, attack=0.01, release=0.08)
            s.drum("drums", "taiko", b, 1.0)
            s.drum("drums", "taiko", b + 0.75, 0.5)
            s.drum("drums", "taiko", b + 2, 0.9)
            s.drum("drums", "snare", b + 1, 0.5)
            s.drum("drums", "snare", b + 3, 0.6)
            for k in range(8):
                s.drum("drums", "hat", b + k * 0.5, 0.2 + 0.1 * (k % 2), 0.4)
            if i % 4 == 3:
                for k in range(8):
                    s.drum("drums", "ltom", b + 2 + k * 0.25, 0.3 + k * 0.08)
        pads(s, "choir", "choir", pr, sec, octave=3, vel=0.55 if sec else 0.35, vowel="a")
        bassline(s, "bass", pr, sec, pattern=((0, 1), (1.5, .5), (2, 1), (3.5, .5)), octave=1, vel=0.7)
        if sec:
            s.drum("drums", "cymbal", sec, 0.7)
            for k in range(2):
                s.drum("drums", "timpani", sec + k * 16, 0.9)
    melody(s, "lead", "brass", 32, theme, 0.85, octave_shift=-1)
    melody(s, "lead", "brass", 64, theme, 0.8)
    melody(s, "lead2", "strings", 64, theme, 0.5, bright=0.9, pan_=0.3)
    melody(s, "lead", "brass", 96, theme, 0.85, octave_shift=-1)
    melody(s, "lead2", "choir", 96, theme, 0.35)
    return s.render({"riff": (0.65, 0.2), "drums": (0.6, 0.25), "choir": (0.55, 0.6), "bass": (0.35, 0.1), "lead": (0.8, 0.3),
                     "lead2": (0.45, 0.4)}, rev=0.25, rev_time=2.8)


# ======================================================================
def music_mystic():
    """Secrets du laboratoire : célesta, cloches, nappes de verre, chœur lointain."""
    s = Song(72, 24)
    prog = ["Emadd9", "Cmaj7", "Am9", "B7sus", "Emadd9", "Cmaj7", "Am9", "Bm"]
    motif = [("B5", 1), ("G5", .5), ("F#5", .5), ("E5", 1), ("B4", 1), ("C6", 1.5), ("B5", .5), ("G5", 2),
             ("A5", 1), ("C6", 1), ("E6", 1), ("D6", 1), ("D#6", 2), ("F#5", 2)]
    for sec in (0, 32, 64):
        for i, c in enumerate(prog):
            b = sec + i * 4
            arp(s, "arp", "celesta", c, b, 4, octave=5 if sec != 32 else 4, step=0.5, pattern=(0, 2, 1, 3, 4, 2, 3, 1), vel=0.35)
        pads(s, "pad", "pad", prog, sec, octave=3, vel=0.45, bright=0.15)
        if sec >= 32:
            pads(s, "choir", "choir", prog, sec, octave=4, vel=0.25, vowel="o")
    for sec in (16, 48, 80):
        melody(s, "lead", "bell", sec, motif, 0.55)
    melody(s, "lead2", "flute", 64, motif, 0.5, octave_shift=-1, pan_=0.3)
    for k in range(12):
        s.note("sparkle", "bell", midi("E7") + [0, 3, 7, 10, 14][k % 5], k * 8 + 3.5, 0.5, 0.18, 0.6 * np.sin(k), ratio=5.1, index=1.0, decay=2.5)
    return s.render({"arp": (0.55, 0.5), "pad": (0.5, 0.6), "choir": (0.35, 0.8), "lead": (0.55, 0.6), "lead2": (0.45, 0.5),
                     "sparkle": (0.4, 0.9)}, rev=0.4, rev_time=4.5)


# ======================================================================
def music_shop():
    """Le marché de Pépite : sol majeur, marimba, clarinette, pizzicati, tambourin."""
    s = Song(112, 32)
    pa = ["G", "Em", "C", "D", "G", "Em", "Am", "D"]
    pb = ["C", "D", "Bm", "Em", "Am", "D", "G", "G"]
    ma = [("B4", .5), ("D5", .5), ("G5", 1), ("F#5", .5), ("E5", .5), ("D5", 1),
          ("E5", .5), ("G5", .5), ("B5", 1), ("A5", 1), ("G5", 1),
          ("E5", 1), ("G5", .5), ("E5", .5), ("C5", 1), ("E5", 1),
          ("F#5", 1), ("A5", 1), ("D5", 2),
          ("B4", .5), ("D5", .5), ("G5", 1), ("A5", .5), ("B5", .5), ("C6", 1),
          ("B5", .5), ("A5", .5), ("G5", 1), ("E5", 2),
          ("A5", 1), ("C6", .5), ("B5", .5), ("A5", 1), ("E5", 1),
          ("F#5", 1), ("E5", .5), ("F#5", .5), ("G5", 2)]
    mb = [("E5", 1), ("G5", 1), ("C6", 1.5), ("B5", .5), ("A5", 1), ("F#5", 1), ("D5", 2),
          ("D5", 1), ("F#5", 1), ("B5", 1.5), ("A5", .5), ("G5", 2), ("E5", 2),
          ("C5", 1), ("E5", 1), ("A5", 1), ("G5", 1), ("F#5", 1), ("A5", 1), ("D6", 2),
          ("B5", 1), ("A5", .5), ("G5", .5), ("F#5", 1), ("A5", 1), ("G5", 4)]
    for sec, pr in ((0, pa), (32, pb), (64, pa), (96, pb)):
        for i, c in enumerate(pr):
            b = sec + i * 4
            r = chord(c, 2)[0]
            walk = [r, r + 4 if "m" not in c else r + 3, r + 7, r + 9]
            for k, p in enumerate(walk):
                s.note("bass", "pizz", p, hum(b + k), 0.8, 0.7)
            for off in (0.5, 1.5, 2.5, 3.5):
                s.chord("chords", "kalimba", chord(c, 4), hum(b + off), 0.4, 0.4, spread=0.7)
            for k in range(8):
                s.drum("perc", "shaker", b + k * 0.5, 0.5 if k % 2 else 0.3, 0.4)
            s.drum("perc", "hat", b + 1, 0.4, -0.3)
            s.drum("perc", "hat", b + 3, 0.4, -0.3)
            s.drum("perc", "kick", b, 0.35)
            s.drum("perc", "kick", b + 2, 0.25)
    melody(s, "lead", "marimba", 0, ma, 0.8)
    melody(s, "lead", "clarinet", 32, mb, 0.75)
    melody(s, "lead", "marimba", 64, ma, 0.75)
    melody(s, "lead2", "flute", 64, ma, 0.45, octave_shift=1, pan_=0.35)
    melody(s, "lead", "clarinet", 96, mb, 0.7)
    melody(s, "lead2", "marimba", 96, mb, 0.5, pan_=-0.35)
    return s.render({"bass": (0.6, 0.15), "chords": (0.35, 0.3), "perc": (0.5, 0.15), "lead": (0.75, 0.3), "lead2": (0.45, 0.3)},
                    rev=0.2, rev_time=1.8)


# ======================================================================
def music_explore():
    """Vers la surface : la majeur, ostinato de cordes, cors, flûte, tambours sur cadre."""
    s = Song(100, 32)
    pa = ["A", "F#m", "D", "E", "A", "F#m", "D", "E"]
    pb = ["D", "E", "C#m", "F#m", "D", "E", "A", "A"]
    ta = [("A4", 1.5), ("E5", .5), ("A5", 1), ("B5", 1), ("C#6", 2), ("B5", 1), ("A5", 1),
          ("F#5", 1.5), ("A5", .5), ("D6", 1), ("C#6", 1), ("B5", 3), ("E5", 1),
          ("A5", 1.5), ("B5", .5), ("C#6", 1), ("E6", 1), ("D6", 1), ("C#6", 1), ("B5", 1), ("A5", 1),
          ("F#5", 1), ("A5", 1), ("B5", 1), ("D6", 1), ("E6", 3), (None, 1)]
    tb = [("F#6", 2), ("E6", 1), ("D6", 1), ("E6", 2), ("D6", 1), ("C#6", 1),
          ("C#6", 1.5), ("B5", .5), ("G#5", 1), ("E5", 1), ("A5", 4),
          ("D6", 1), ("C#6", 1), ("B5", 1), ("A5", 1), ("G#5", 2), ("B5", 2), ("A5", 4), (None, 4)]
    for sec, pr in ((0, pa), (32, pa), (64, pb), (96, pa)):
        for i, c in enumerate(pr):
            b = sec + i * 4
            r = chord(c, 3)[0]
            for k, iv in enumerate([0, 7, 12, 7, 0, 7, 12, 16]):
                s.note("ost", "strings", r + iv, hum(b + k * 0.5, 0.004), 0.42, 0.3, 0.2 if k % 2 else -0.2, attack=0.01, release=0.1, bright=0.7)
            s.drum("perc", "frame", b, 0.7)
            s.drum("perc", "frame", b + 1.5, 0.4)
            s.drum("perc", "frame", b + 2, 0.6)
            s.drum("perc", "frame", b + 3.5, 0.4)
            for k in range(4):
                s.drum("perc", "shaker", b + k + 0.5, 0.3, 0.4)
        pads(s, "str", "strings", pr, sec, octave=3, vel=0.35, bright=0.4)
        bassline(s, "bass", pr, sec, pattern=((0, 2), (2, 1.5), (3.5, .5)), vel=0.55)
        if sec:
            s.drum("perc", "cymbal", sec, 0.5)
            s.drum("perc", "timpani", sec, 0.6, 0)
    melody(s, "lead", "flute", 0, ta, 0.7, octave_shift=-1)
    melody(s, "lead", "brass", 32, ta, 0.8, octave_shift=-1)
    melody(s, "lead2", "strings", 32, ta, 0.4, pan_=0.3, bright=0.8)
    melody(s, "lead", "strings", 64, tb, 0.75, bright=0.9)
    melody(s, "lead2", "brass", 64, tb, 0.55, octave_shift=-1, pan_=-0.3)
    pads(s, "choir", "choir", pb, 64, octave=3, vel=0.4)
    melody(s, "lead", "brass", 96, ta, 0.85, octave_shift=-1)
    melody(s, "lead2", "flute", 96, ta, 0.5, pan_=0.3)
    for i, c in enumerate(pa):
        arp(s, "harp", "harp", c, 96 + i * 4, 4, octave=5, step=0.25, pattern=(0, 1, 2, 3), vel=0.2)
    return s.render({"ost": (0.5, 0.25), "perc": (0.6, 0.2), "str": (0.4, 0.45), "bass": (0.55, 0.15), "lead": (0.75, 0.3),
                     "lead2": (0.45, 0.35), "choir": (0.35, 0.6), "harp": (0.4, 0.4)}, rev=0.28, rev_time=2.8)


# ======================================================================
def amb_cave():
    """Ambiance de caverne : vent grave, gouttes résonnantes, grondements, cristaux."""
    dur = 48.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    wind = lp(RNG.standard_normal(n), 380) * (0.5 + 0.5 * np.sin(2 * np.pi * t / dur * 2) ** 2)
    wind2 = bp(RNG.standard_normal(n), 300, 900) * 0.15 * (0.5 + 0.5 * np.sin(2 * np.pi * t / dur * 3 + 1))
    base = np.stack([wind + wind2, np.roll(wind, SR // 3) + wind2]) * 0.35
    tr = Track(dur)
    for k in range(70):
        at = RNG.uniform(0, dur - 0.5)
        f = RNG.uniform(900, 2400)
        m = int(0.25 * SR)
        tt_ = np.arange(m) / SR
        drip = np.sin(2 * np.pi * np.cumsum(f * (1 + 0.6 * np.exp(-tt_ * 40))) / SR) * np.exp(-tt_ * 22)
        tr.add(drip * RNG.uniform(0.1, 0.35), at, 1.0, RNG.uniform(-0.8, 0.8))
    for k in range(5):
        at = RNG.uniform(0, dur - 4)
        m = int(4 * SR)
        rumble = lp(RNG.standard_normal(m), 90) * np.sin(np.linspace(0, np.pi, m)) * 1.8
        tr.add(rumble, at, 1.0, 0)
    for k in range(6):
        at = RNG.uniform(0, dur - 3)
        tr.add(bell(hz(midi("E6") + int(RNG.choice([0, 3, 7, 10, 12]))), 0.5, 0.12, ratio=5.0, index=0.8, decay=1.2), at, 1.0, RNG.uniform(-0.7, 0.7))
    wet = reverb(tr.buf, 0.6, 4.0)
    mix = wet[:, :n] + base
    extra = wet[:, n:n + 6 * SR]
    mix[:, :extra.shape[1]] += extra
    return master(mix, 0.6)


# ======================================================================
def _short(seconds):
    return Song(60, 1), int(seconds * SR)


def jingle(build, seconds, rev=0.3):
    tr = Track(seconds)
    build(tr)
    out = reverb(tr.buf, rev, 2.4)
    return master(out[:, :int((seconds + 1.5) * SR)])


def jingle_victory():
    def b(tr):
        notes = [("D5", 0.0), ("F#5", 0.18), ("A5", 0.36), ("D6", 0.54)]
        for p, at in notes:
            tr.add(brass(hz(p), 0.3, 0.8), at, 0.7, 0.0)
            tr.add(strings(hz(p), 0.3, 0.5, bright=0.9), at, 0.4, 0.2)
        for p in ("D4", "F#4", "A4", "D5", "F#5", "A5"):
            tr.add(brass(hz(p), 2.0, 0.55), 0.8, 0.45, RNG.uniform(-0.5, 0.5))
            tr.add(choir(hz(p), 2.0, 0.35), 0.8, 0.3, RNG.uniform(-0.5, 0.5))
        for k in range(10):
            tr.add(timpani(0.3 + k * 0.05, hz("D2")), 0.3 + k * 0.05, 0.6)
        tr.add(timpani(1.0, hz("D2")), 0.8, 0.9)
        tr.add(cymbal(0.8, 3.0), 0.8, 0.7)
        for k, p in enumerate(("D6", "F#6", "A6", "D7")):
            tr.add(bell(hz(p), 0.5, 0.4), 0.85 + k * 0.08, 0.5, 0.5)
    return jingle(b, 4.0)


def jingle_defeat():
    def b(tr):
        for k, p in enumerate(("A4", "G4", "F4", "E4")):
            tr.add(strings(hz(p), 0.7, 0.6, bright=0.3), k * 0.6, 0.6)
        for p in ("D3", "A3", "D4", "F4"):
            tr.add(strings(hz(p), 2.0, 0.4, bright=0.2), 2.4, 0.5, RNG.uniform(-0.4, 0.4))
            tr.add(choir(hz(p), 2.0, 0.3, vowel="o"), 2.4, 0.4)
        tr.add(timpani(0.7, hz("D2")), 2.4, 0.7)
    return jingle(b, 4.6)


def jingle_levelup():
    def b(tr):
        for k, p in enumerate(("D5", "F#5", "A5", "D6", "F#6", "A6")):
            tr.add(harp(hz(p), 0.5, 0.6), k * 0.06, 0.7, -0.5 + k * 0.2)
        for p in ("D6", "A6", "D7"):
            tr.add(bell(hz(p), 1.0, 0.5), 0.4, 0.5, 0.3)
        tr.add(choir(hz("A5"), 0.9, 0.3), 0.35, 0.4)
    return jingle(b, 1.8)


def jingle_quest():
    def b(tr):
        for k, p in enumerate(("G5", "B5", "D6")):
            tr.add(celesta(hz(p), 0.3, 0.7), k * 0.1, 0.8)
        for p in ("G4", "B4", "D5", "G5"):
            tr.add(brass(hz(p), 0.8, 0.5), 0.32, 0.4, RNG.uniform(-0.4, 0.4))
        tr.add(bell(hz("G6"), 1.0, 0.5), 0.32, 0.5)
    return jingle(b, 2.0)


def jingle_reveal(rarity):
    """Révélation d'invocation : plus la rareté est haute, plus c'est grandiose."""
    roots = ["C5", "D5", "E5", "D5"]
    def b(tr):
        root = midi(roots[rarity])
        up = [0, 4, 7, 12, 16, 19, 24][:4 + rarity]
        for k, iv in enumerate(up):
            tr.add(harp(hz(root + iv), 0.4, 0.6), k * 0.07, 0.6, -0.6 + k * 0.2)
        hit = 0.1 + 0.07 * len(up)
        for iv in (0, 4, 7, 12):
            tr.add(bell(hz(root + iv + 12), 1.2, 0.5), hit, 0.5, RNG.uniform(-0.5, 0.5))
        if rarity >= 1:
            for iv in (0, 7, 12, 16):
                tr.add(strings(hz(root + iv - 12), 1.6, 0.5, bright=0.7), hit, 0.45)
        if rarity >= 2:
            for iv in (0, 4, 7, 12):
                tr.add(choir(hz(root + iv - 12), 2.2, 0.45), hit, 0.45)
            tr.add(cymbal(0.7, 3.0), hit, 0.6)
            tr.add(timpani(0.9, hz(root - 36)), hit, 0.7)
        if rarity >= 3:
            for iv in (0, 4, 7, 12, 16):
                tr.add(brass(hz(root + iv - 12), 2.4, 0.6), hit + 0.05, 0.5, RNG.uniform(-0.5, 0.5))
            for k in range(14):
                tr.add(bell(hz(root + 24 + [0, 4, 7, 12][k % 4]), 0.3, 0.3, ratio=5.0, index=1.0), hit + 0.2 + k * 0.09, 0.4, RNG.uniform(-0.8, 0.8))
            tr.add(taiko(1.0), hit, 0.8)
    return jingle(b, [1.8, 2.4, 3.2, 4.2][rarity], rev=0.35)


TRACKS = {
    "music_menu": music_menu, "music_city": music_city, "music_battle": music_battle, "music_boss": music_boss,
    "music_mystic": music_mystic, "music_shop": music_shop, "music_explore": music_explore, "amb_cave": amb_cave,
    "jingle_victory": jingle_victory, "jingle_defeat": jingle_defeat, "jingle_levelup": jingle_levelup, "jingle_quest": jingle_quest,
    "jingle_reveal_0": lambda: jingle_reveal(0), "jingle_reveal_1": lambda: jingle_reveal(1),
    "jingle_reveal_2": lambda: jingle_reveal(2), "jingle_reveal_3": lambda: jingle_reveal(3),
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(TRACKS)
    for name in names:
        x = TRACKS[name]()
        q = 5 if name.startswith(("music", "amb")) else 6
        path = save_ogg(name, x, quality=q)
        print("%-18s %6.1f s" % (name, x.shape[1] / SR))
