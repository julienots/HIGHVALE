"""Créature : Dragonnet rose. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "slime_pink", "scale_belly", "fire", eyes="dark", deco=[], tail='thin', ears='round', wingc='membrane')
