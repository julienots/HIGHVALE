"""Héros : Azura (Impératrice du ciel). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "gold", weapon=lambda m, x, z: staff(m, x, z, "rune", "gold"), offhand=lambda m, x, z: orb(m, x, z, "rune"), skin="skin_dark", hair="hair_white", crown="gold", wings="feather_white", cape="cloth_blue", glow="glow_teal", eyes="crystal", hair_style="long")
