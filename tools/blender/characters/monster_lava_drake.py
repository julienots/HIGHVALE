"""Créature : Drake de lave. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "scale_red", "lava", "fire", eyes="fire", deco=['flame', 'spikes:lava'], tail='long', wingc='membrane', fangs=True)
