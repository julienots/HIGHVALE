"""Créature : Pinson de feu. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "feather_red", "fur_orange", "gold", eyes="dark", deco=['flame'], crest='fire', tail='fan')
