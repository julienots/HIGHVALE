"""Créature : Cobra royal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "scale_gold", "scale_belly", "cloth_red", eyes="glow_gold", deco=['crown:gold'], hood=True, fangs=True)
