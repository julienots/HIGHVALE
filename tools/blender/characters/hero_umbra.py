"""Héros : Umbra (Chevalière du crépuscule). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "steel_dark", "cloth_purple", weapon=lambda m, x, z: katana(m, x, z, "shadow_glow"), skin="skin_pale", hair="hair_silver", armor="steel_dark", pauldrons="steel_dark", cape="cloth_purple", glow="shadow_glow", hair_style="bob")
