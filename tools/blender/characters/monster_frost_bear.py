"""Créature : Ours de givre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_white", "ice", "crystal", eyes="glow_blue", deco=['crystals:ice'], ears='round', bulk=1.45, tail='none')
