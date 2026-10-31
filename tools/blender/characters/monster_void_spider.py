"""Créature : Araignée du Néant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "void_skin", "fur_black", "glow_violet", eyes="glow_violet", deco=['glowspots:glow_violet'])
