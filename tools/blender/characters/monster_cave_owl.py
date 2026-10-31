"""Créature : Hibou des cavernes. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "fur_brown", "fur_sand", "gold", eyes="glow_gold", deco=[])
