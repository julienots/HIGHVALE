"""Héros : Brunhild (Forgeronne des runes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_red", weapon=lambda m, x, z: greataxe(m, x, z), hair="hair_blond", armor="iron", pauldrons="iron", glow="fire", hair_style="braids")
