"""Créature : Esprit d'orage. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "glow_blue", "fur_white", "glow_gold", eyes="dark", deco=[], kind='wisp', light='c8d8ff')
