"""Créature : Feu de givre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "glow_blue", "ice", "glow_blue", eyes="dark", deco=[], kind='flame', light='8ac8ff')
