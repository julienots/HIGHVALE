"""Créature : Golem d'obsidienne. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "fur_black", "void_skin", "shadow_glow", eyes="shadow_glow", deco=['runes:shadow_glow'])
