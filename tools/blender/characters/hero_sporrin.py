"""Héros : Sporrin (Mage-champignon). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "mushroom_violet", "cloth_brown", weapon=lambda m, x, z: staff(m, x, z, "glow_violet", "bark"), hair="hair_white", hat=('witch', 'mushroom_violet'), hair_style="short")
