"""Créature : Sanglier de pierre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "rock", "rock_light", "moss", eyes="glow_gold", deco=['moss', 'spikes:rock_light'], ears='round', bulk=1.3, legs='short')
