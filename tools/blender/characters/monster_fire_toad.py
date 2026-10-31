"""Créature : Crapaud de feu. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["frog"]


def build(m):
    creature(m, "frog", "scale_red", "fur_orange", "fire", eyes="dark", deco=['flame'])
