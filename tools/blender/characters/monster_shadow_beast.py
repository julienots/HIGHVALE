"""Créature : Bête d'ombre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["brute"]


def build(m):
    creature(m, "brute", "fur_black", "void_skin", "shadow_glow", eyes="shadow_glow", deco=['horns:shadow_glow', 'glowspots:shadow_glow'], fangs=True)
