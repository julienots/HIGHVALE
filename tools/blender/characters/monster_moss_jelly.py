"""Créature : Gelée moussue. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["blob"]


def build(m):
    creature(m, "blob", "slime", "moss", "glow_green", eyes="dark", deco=['moss', 'mushrooms:mushroom_pink'])
