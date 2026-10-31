"""Créature : Oiseau-tonnerre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "feather_blue", "feather_white", "gold", eyes="glow_gold", deco=['crown:glow_gold'], crest='glow_gold', tail='fan')
