"""Héros : Faye (Enchanteresse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_green", weapon=lambda m, x, z: wand(m, x, z, "glow_pink"), offhand=lambda m, x, z: orb(m, x, z, "glow_pink"), skin="skin_pale", hair="hair_red", ears="elf", hat=('flower', 'glow_pink'), hair_style="long")
