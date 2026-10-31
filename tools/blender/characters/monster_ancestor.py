"""Créature : Esprit ancestral. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["spirit"]


def build(m):
    creature(m, "spirit", "ghost", "glow_teal", "gold", eyes="glow_teal", deco=['crown:gold', 'halo:glow_teal'], kind='ghost', light='a8fff2')
