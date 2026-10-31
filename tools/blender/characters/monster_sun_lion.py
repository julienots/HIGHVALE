"""Créature : Lion solaire. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "scale_gold", "fur_sand", "glow_gold", eyes="glow_gold", deco=['halo:glow_gold'], mane='fur_orange', tail='thin', bulk=1.25, ears='round')
