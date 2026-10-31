"""Créature : Roc géant. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "fur_brown", "feather_white", "bone", eyes="glow_gold", deco=['horns:bone'], crest='fur_brown', tail='fan')
