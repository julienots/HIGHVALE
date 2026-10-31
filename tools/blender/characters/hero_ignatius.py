"""Héros : Ignatius (Pyromancien). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_black", weapon=lambda m, x, z: staff(m, x, z, "fire", "gold"), offhand=lambda m, x, z: flame_hand(m, x, z), hair="hair_red", hat=('wizard', 'cloth_red'), eyes="fire", hair_style="spiky")
