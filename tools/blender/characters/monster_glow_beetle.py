"""Créature : Scarabée lumineux. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "scale_gold", "dark", "glow_gold", eyes="dark", deco=['glowspots:glow_gold'])
