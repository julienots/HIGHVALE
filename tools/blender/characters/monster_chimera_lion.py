"""Créature : Manticore. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_orange", "fur_sand", "scale_red", eyes="fire", deco=['spikes:scale_red'], wings=True, wingc='membrane', tail='club', mane='fur_brown', fangs=True)
