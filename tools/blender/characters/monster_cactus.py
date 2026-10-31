"""Créature : Cactus grognon. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "scale_green", "mushroom_pink", "cloth_white", eyes="dark", deco=[], kind='cactus')
