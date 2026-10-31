"""Créature : Cerf esprit. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "ghost", "fur_white", "glow_teal", eyes="glow_teal", deco=['antlers:glow_teal', 'glowspots:glow_teal'], tail='thin', light='a8fff2')
