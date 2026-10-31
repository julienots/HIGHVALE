"""Créature : Banshee. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "ghost", "glow_violet", "glow_violet", eyes="glow_violet", deco=['crown:steel_dark'], kind='ghost', light='b49cff')
