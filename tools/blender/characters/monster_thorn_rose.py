"""Créature : Rose épineuse. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "leaf_dark", "feather_red", "fur_black", eyes="dark", deco=['spikes:leaf_dark'], kind='flower')
