"""Créature : Méduse abyssale. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["jelly"]


def build(m):
    creature(m, "jelly", "glow_violet", "slime_violet", "shadow_glow", eyes="dark", deco=['crown:steel_dark'], light='b49cff')
