"""Créature : Golem de galets. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "rock_light", "rock", "glow_gold", eyes="glow_gold", deco=['moss'])
