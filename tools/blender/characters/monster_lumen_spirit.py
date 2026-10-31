"""Créature : Esprit de lumière. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "glow_gold", "glow_gold", "glow_gold", eyes="dark", deco=['halo:glow_gold'], kind='wisp')
