"""Créature : Golem de glace. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["golem"]


def build(m):
    creature(m, "golem", "ice", "crystal", "glow_blue", eyes="glow_blue", deco=['crystals:ice'])
