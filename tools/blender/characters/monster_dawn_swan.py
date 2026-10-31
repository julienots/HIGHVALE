"""Créature : Cygne d'aurore. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "feather_white", "fur_white", "gold", eyes="dark", deco=['halo:glow_gold'], tail='fan')
