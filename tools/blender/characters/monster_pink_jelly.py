"""Créature : Gelée rose. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["blob"]


def build(m):
    creature(m, "blob", "slime_pink", "cloth_white", "glow_pink", eyes="dark", deco=[])
