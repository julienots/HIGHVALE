"""Créature : Troll des cavernes. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["brute"]


def build(m):
    creature(m, "brute", "skin_green", "fur_brown", "moss", eyes="dark", deco=['moss'], fangs=True)
