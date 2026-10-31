"""Créature : Méduse de lune. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["jelly"]


def build(m):
    creature(m, "jelly", "glow_blue", "slime", "glow_teal", eyes="dark", deco=[], light='8ac8ff')
