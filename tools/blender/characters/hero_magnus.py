"""Héros : Magnus (Archimage). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "gold", weapon=lambda m, x, z: staff(m, x, z, "fire", "gold"), offhand=lambda m, x, z: tome(m, x, z, "cloth_red"), hair="hair_white", beard=True, hat=('wizard', 'cloth_red'), cape="cloth_red", glow="fire", eyes="fire", hair_style="long")
