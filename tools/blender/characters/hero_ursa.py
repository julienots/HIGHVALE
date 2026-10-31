"""Héros : Ursa (Chamane ourse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "fur_brown", "cloth_brown", weapon=lambda m, x, z: staff(m, x, z, "glow_teal", "bark"), offhand=lambda m, x, z: orb(m, x, z, "leaf"), skin="skin_dark", hair="hair_black", hood="fur_brown", ears="fur_brown", glow="glow_teal", hair_style="braids")
