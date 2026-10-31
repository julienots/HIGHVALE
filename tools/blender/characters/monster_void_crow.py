"""Créature : Corneille du Néant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "void_skin", "feather_black", "glow_violet", eyes="glow_violet", deco=['glowspots:glow_violet'])
