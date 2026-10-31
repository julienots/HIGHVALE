"""Héros : Yara (Charmeuse de serpents). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "cloth_orange", weapon=lambda m, x, z: whip(m, x, z, "leaf"), offhand=lambda m, x, z: lute(m, x, z), skin="skin_dark", hair="hair_black", hat=('circlet', 'gold'), hair_style="long")
