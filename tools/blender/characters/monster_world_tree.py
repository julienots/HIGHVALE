"""Créature : Pousse d'Yggdra. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "bark", "leaf", "glow_gold", eyes="glow_gold", deco=['leaves:leaf_autumn', 'halo:glow_gold'], kind='bulb')
