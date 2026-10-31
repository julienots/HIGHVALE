"""Créature : Cerf moussu. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_brown", "fur_sand", "moss", eyes="dark", deco=['antlers:bark', 'moss'], ears='pointy', tail='thin')
