"""Héros : Hilda (Valkyrie). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "steel", "cloth_blue", weapon=lambda m, x, z: spear(m, x, z, "steel"), offhand=lambda m, x, z: shield(m, x, z, "cloth_blue", "steel"), hair="hair_blond", hat=('horned', 'steel'), wings="feather_white", armor="steel", pauldrons="steel", hair_style="braids")
