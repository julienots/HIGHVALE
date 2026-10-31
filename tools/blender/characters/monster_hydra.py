"""Créature : Hydre des marais. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "scale_green", "scale_belly", "leaf_dark", eyes="glow_gold", deco=['spikes:leaf_dark', 'horns:bone'], segments=9, fins=True, fangs=True)
