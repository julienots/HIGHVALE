"""Héros : Aube (Archère du soleil levant). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: bow(m, x, z), hair="hair_blond", ears="elf", hat=('circlet', 'gold'), cape="cloth_orange", glow="glow_gold", hair_style="ponytail")
