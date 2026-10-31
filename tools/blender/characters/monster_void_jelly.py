"""Créature : Gelée du Néant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["blob"]


def build(m):
    creature(m, "blob", "slime_violet", "void_skin", "glow_violet", eyes="glow_violet", deco=['glowspots:glow_violet'])
