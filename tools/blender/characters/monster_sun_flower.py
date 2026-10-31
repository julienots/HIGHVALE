"""Créature : Tournesol vivant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "leaf", "scale_gold", "fur_brown", eyes="dark", deco=[], kind='flower')
