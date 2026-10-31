"""Héros : Sélène (Prismatiste). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_white", weapon=lambda m, x, z: wand(m, x, z, "crystal"), offhand=lambda m, x, z: orb(m, x, z, "crystal"), hair="hair_blue", eyes="crystal", hat=('circlet', 'gold'), hair_style="long")
