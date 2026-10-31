"""Créature : Crabe-roi. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["crab"]


def build(m):
    creature(m, "crab", "shell_red", "fur_sand", "shell_red", eyes="dark", deco=['crown:gold', 'spikes:shell_red'])
