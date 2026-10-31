"""Créature : Basilic. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "scale_green", "rock_light", "gold", eyes="glow_gold", deco=['crown:gold', 'spikes:rock'], ears='none', tail='long', bulk=1.2, fangs=True)
