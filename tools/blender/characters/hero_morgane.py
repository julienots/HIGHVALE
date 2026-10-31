"""Héros : Morgane (Sorcière des marées). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_black", weapon=lambda m, x, z: staff(m, x, z, "crystal_teal", "steel"), offhand=lambda m, x, z: orb(m, x, z, "water"), skin="skin_pale", hair="hair_blue", hat=('witch', 'cloth_blue'), eyes="crystal", hair_style="long")
