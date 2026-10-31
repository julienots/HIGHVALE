"""Héros : Elara (Astronome). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_white", weapon=lambda m, x, z: staff(m, x, z, "glow_gold", "gold"), offhand=lambda m, x, z: orb(m, x, z, "glow_gold"), skin="skin_dark", hair="hair_black", hat=('wizard', 'cloth_blue'), hair_style="long")
