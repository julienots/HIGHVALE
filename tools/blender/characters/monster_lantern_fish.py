"""Créature : Poisson-lanterne. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["fish"]


def build(m):
    creature(m, "fish", "eel_blue", "cloth_white", "glow_gold", eyes="dark", deco=['glowspots:glow_gold'])
