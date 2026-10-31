"""Créature : Yéti. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["brute"]


def build(m):
    creature(m, "brute", "fur_white", "skin_blue", "ice", eyes="dark", deco=['horns:bone'], fangs=True)
