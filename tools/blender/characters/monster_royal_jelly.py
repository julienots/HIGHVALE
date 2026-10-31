"""Créature : Gelée royale. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["blob"]


def build(m):
    creature(m, "blob", "slime_gold", "cloth_white", "glow_gold", eyes="dark", deco=['crown:gold'], tall=1.15)
