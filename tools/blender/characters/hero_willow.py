"""Héros : Saule (Druidesse ancienne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf", "bark", weapon=lambda m, x, z: staff(m, x, z, "glow_teal", "bark"), offhand=lambda m, x, z: orb(m, x, z, "leaf"), skin="skin_pale", hair="hair_white", ears="elf", crown="leaf", skirt="leaf_dark", eyes="glow_teal", hair_style="long")
