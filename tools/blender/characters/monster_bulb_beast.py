"""Créature : Bulbe dormant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "leaf_dark", "slime", "glow_teal", eyes="dark", deco=[], kind='bulb')
