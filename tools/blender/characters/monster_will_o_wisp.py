"""Créature : Feu des marais. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "fire", "lava", "glow_gold", eyes="dark", deco=[], kind='flame', light='ffa040')
