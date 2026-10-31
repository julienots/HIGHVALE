"""Créature : Guêpe d'orage. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "scale_gold", "fur_black", "glow_gold", eyes="dark", deco=[], wings='glass', stinger=True)
