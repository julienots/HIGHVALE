"""Créature : Fourmi de lave. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "scale_red", "fur_black", "fire", eyes="dark", deco=[])
