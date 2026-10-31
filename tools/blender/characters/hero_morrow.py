"""Héros : Lendemain (Devin aveugle). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_purple", weapon=lambda m, x, z: staff(m, x, z, "glow_violet", "wood_dark"), offhand=lambda m, x, z: orb(m, x, z, "glow_violet"), skin="skin_dark", hair="hair_white", beard=True, mask="cloth_white", glow="glow_violet", hair_style="bald")
