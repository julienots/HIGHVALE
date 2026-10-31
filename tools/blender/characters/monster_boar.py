"""Créature : Sanglier des galeries. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_brown", "fur_sand", "bone", eyes="dark", deco=['horns:bone'], ears='round', bulk=1.2, snout=0.07, fangs=True)
