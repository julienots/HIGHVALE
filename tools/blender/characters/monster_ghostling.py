"""Créature : Fantômet. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "ghost", "ghost", "glow_violet", eyes="dark", deco=[], kind='ghost')
