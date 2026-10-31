"""Créature : Naga de givre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "scale_blue", "ice", "crystal", eyes="crystal", deco=['crystals:ice'], hood=True, fins=True)
