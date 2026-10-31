"""Héros : Marek (Vétéran borgne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_brown", weapon=lambda m, x, z: greataxe(m, x, z), hair="hair_silver", beard=True, armor="iron", pauldrons="fur_brown", mask="cloth_black", hair_style="short")
