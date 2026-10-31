"""Créature : Dragon d'or. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "scale_gold", "scale_belly", "gold", eyes="glow_gold", deco=['crown:gold', 'spikes:gold'], tail='long', wingc='gold', bulk=1.3)
