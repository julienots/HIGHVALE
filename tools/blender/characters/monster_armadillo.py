"""Créature : Tatou blindé. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_sand", "skin_pale", "bone", eyes="dark", deco=['shell:rock_light'], ears='round', legs='short', tail='thin')
