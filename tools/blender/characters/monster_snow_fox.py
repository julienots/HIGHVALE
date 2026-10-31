"""Créature : Renard des neiges. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_white", "ice", "glow_blue", eyes="dark", deco=[], tail='bushy', tailc='fur_white')
