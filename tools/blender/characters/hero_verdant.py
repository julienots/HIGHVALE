"""Héros : Verdant (Seigneur des racines). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf_dark", "bark", weapon=lambda m, x, z: staff(m, x, z, "glow_teal", "bark"), offhand=lambda m, x, z: orb(m, x, z, "leaf"), skin="skin_green", hair="leaf", eyes="glow_teal", crown="bark", cape="leaf", glow="glow_teal", horns="bark", hair_style="mane")
