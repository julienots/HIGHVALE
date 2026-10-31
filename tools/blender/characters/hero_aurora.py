"""Héros : Boréale (Danseuse des lueurs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_white", weapon=lambda m, x, z: fan(m, x, z, "cloth_teal"), offhand=lambda m, x, z: fan(m, x, z, "cloth_white"), skin="skin_dark", hair="hair_blue", hat=('circlet', 'gold'), skirt="cloth_teal", glow="glow_teal", hair_style="long")
