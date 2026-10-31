"""Créature : Wyrm d'ombre. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["drake"]


def build(m):
    creature(m, "drake", "fur_black", "void_skin", "shadow_glow", eyes="shadow_glow", deco=['spikes:shadow_glow', 'runes:shadow_glow'], tail='long', wingc='membrane', fangs=True, bulk=1.3)
