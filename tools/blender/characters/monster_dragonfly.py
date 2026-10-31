"""Créature : Libellule des sources. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "shell_teal", "eel_blue", "glow_teal", eyes="dark", deco=[], wings='glass')
