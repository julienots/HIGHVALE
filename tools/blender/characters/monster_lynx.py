"""Créature : Lynx d'ombre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_violet", "fur_black", "shadow_glow", eyes="glow_violet", deco=[], tail='thin', ears='pointy')
