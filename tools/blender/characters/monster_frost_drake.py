"""Créature : Drake de givre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "scale_blue", "ice", "crystal", eyes="glow_blue", deco=['crystals:ice'], tail='long', ears='fins', wingc='ice', fangs=True)
