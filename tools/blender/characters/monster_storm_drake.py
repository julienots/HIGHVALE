"""Créature : Drake d'orage. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "scale_blue", "fur_white", "glow_gold", eyes="glow_gold", deco=['spikes:glow_gold'], tail='long', wingc='feather_blue', fangs=True)
