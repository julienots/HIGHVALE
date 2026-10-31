"""Créature : Gelée de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["blob"]


def build(m):
    creature(m, "blob", "ice", "crystal", "glow_blue", eyes="dark", deco=['crystals:crystal'])
