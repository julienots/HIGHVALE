"""Créature : Golem de lave. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "rock", "lava", "fire", eyes="fire", deco=['flame'])
