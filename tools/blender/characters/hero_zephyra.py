"""Héros : Zéphyra (Danseuse des vents). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_teal", weapon=lambda m, x, z: fan(m, x, z, "cloth_teal"), offhand=lambda m, x, z: fan(m, x, z, "cloth_white"), skin="skin_pale", hair="hair_white", wings="feather_white", eyes="crystal", hair_style="twintails")
