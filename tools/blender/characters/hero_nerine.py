"""Héros : Nérine (Sirène des lacs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_teal", weapon=lambda m, x, z: lute(m, x, z), offhand=lambda m, x, z: orb(m, x, z, "water"), skin="skin_blue", hair="hair_blue", hat=('circlet', 'gold'), skirt="cloth_teal", hair_style="long")
