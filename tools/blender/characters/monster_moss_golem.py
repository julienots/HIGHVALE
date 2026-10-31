"""Créature : Golem moussu. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "rock", "moss", "glow_green", eyes="glow_green", deco=['moss', 'mushrooms:mushroom_teal'])
