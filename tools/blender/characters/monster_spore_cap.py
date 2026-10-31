"""Créature : Champi-spore. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "mushroom_stem", "mushroom_teal", "glow_teal", eyes="dark", deco=[], kind='mushroom')
