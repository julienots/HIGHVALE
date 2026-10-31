"""Créature : Tortue des sources. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "scale_green", "scale_belly", "moss", eyes="dark", deco=['shell:shell_teal', 'moss'], ears='none', legs='short', tail='thin')
