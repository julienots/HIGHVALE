"""Créature : Dragon des mers. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "scale_blue", "scale_belly", "shell_teal", eyes="glow_teal", deco=['spikes:shell_teal', 'horns:bone'], segments=9, fins=True, fangs=True)
