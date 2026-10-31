"""Héros : Lutine (Fée des lueurs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_white", weapon=lambda m, x, z: wand(m, x, z, "glow_pink"), skin="skin_pale", hair="hair_blond", ears="elf", wings="glass", hair_style="twintails")
