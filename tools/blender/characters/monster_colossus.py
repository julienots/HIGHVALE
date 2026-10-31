"""Créature : Colosse runique. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "marble", "gold", "rune", eyes="rune", deco=['runes:rune', 'crown:gold'])
