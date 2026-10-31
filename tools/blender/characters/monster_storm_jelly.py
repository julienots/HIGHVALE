"""Créature : Méduse d'orage. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["jelly"]


def build(m):
    creature(m, "jelly", "glow_gold", "scale_gold", "glow_blue", eyes="dark", deco=[], light='ffe680')
