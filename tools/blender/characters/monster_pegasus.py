"""Créature : Pégase. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_white", "feather_white", "gold", eyes="dark", deco=['halo:glow_gold'], wings=True, wingc='feather_white', mane='feather_white', tail='bushy', tailc='feather_white', snout=0.06)
