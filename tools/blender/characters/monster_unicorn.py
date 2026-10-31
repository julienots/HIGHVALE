"""Créature : Licorne. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_white", "fur_white", "gold", eyes="dark", deco=['horn:gold'], mane='glow_pink', tail='bushy', tailc='glow_pink', snout=0.06)
