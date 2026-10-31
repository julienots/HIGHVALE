"""Créature : Griffon. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_sand", "feather_white", "gold", eyes="glow_gold", deco=[], wings=True, wingc='feather_white', tail='thin', ears='pointy', mane='feather_white')
