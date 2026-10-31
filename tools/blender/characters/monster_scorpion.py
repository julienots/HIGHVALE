"""Créature : Scorpion des sables. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "fur_sand", "scale_red", "dark", eyes="dark", deco=[], stinger=True)
