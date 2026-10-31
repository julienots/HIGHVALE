"""Créature : Crapaud sage. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["frog"]


def build(m):
    creature(m, "frog", "fur_brown", "fur_sand", "moss", eyes="dark", deco=['mushrooms:mushroom_pink', 'moss'])
