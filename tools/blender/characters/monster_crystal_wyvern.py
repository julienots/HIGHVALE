"""Créature : Vouivre de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "crystal", "ice", "crystal_violet", eyes="crystal", deco=['crystals:crystal_violet'], tail='long', wingc='glass')
