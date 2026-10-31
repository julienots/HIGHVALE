"""Héros : Céleste (Oracle des nuages). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: staff(m, x, z, "glow_gold", "gold"), offhand=lambda m, x, z: orb(m, x, z, "glow_gold"), skin="skin_pale", hair="hair_silver", wings="feather_white", crown="gold", skirt="cloth_white", glow="glow_gold", eyes="glow_gold", hair_style="long")
