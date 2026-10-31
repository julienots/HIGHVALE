"""Créature : Scarabée titan. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "chitin_blue", "fur_black", "gold", eyes="glow_gold", deco=['horn:gold', 'spikes:gold'])
