"""Créature : Piranha des abysses. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["fish"]


def build(m):
    creature(m, "fish", "fur_grey", "feather_red", "cloth_red", eyes="dark", deco=['spikes:cloth_white'])
