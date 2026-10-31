"""Héros : Cyrus (Chevalier de cristal). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "crystal", "steel", weapon=lambda m, x, z: sword(m, x, z, "crystal"), offhand=lambda m, x, z: shield(m, x, z, "crystal_teal", "crystal"), hair="hair_silver", armor="crystal", pauldrons="crystal", helmet="crystal", glow="rune", eyes="crystal", hair_style="short")
