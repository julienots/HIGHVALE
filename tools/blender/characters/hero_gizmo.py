"""Héros : Gizmo (Inventeur fou). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_brown", "leather", weapon=lambda m, x, z: wrench(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "bronze"), hair="hair_white", goggles="bronze", pouch="leather", beard=True, hair_style="spiky")
