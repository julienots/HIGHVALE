"""Créature : Ours des cavernes. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_brown", "fur_sand", "bone", eyes="dark", deco=[], ears='round', bulk=1.4, tail='none', snout=0.05)
