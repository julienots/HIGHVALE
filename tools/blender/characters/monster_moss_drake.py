"""Créature : Drake moussu. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "scale_green", "scale_belly", "bark", eyes="glow_gold", deco=['moss', 'leaves:leaf'], tail='long', ears='fins', wingc='leaf')
