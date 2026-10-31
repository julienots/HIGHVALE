"""Créature : Serpent de lave. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "lava", "fire", "scale_red", eyes="fire", deco=['flame'], fangs=True)
