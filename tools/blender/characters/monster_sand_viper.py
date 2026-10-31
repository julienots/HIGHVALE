"""Créature : Vipère des sables. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "fur_sand", "scale_belly", "cloth_red", eyes="dark", deco=[], fangs=True)
