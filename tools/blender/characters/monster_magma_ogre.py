"""Créature : Ogre de magma. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["brute"]


def build(m):
    creature(m, "brute", "rock", "lava", "fire", eyes="fire", deco=['flame', 'horns:rock'], fangs=True)
