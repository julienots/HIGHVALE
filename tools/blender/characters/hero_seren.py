"""Héros : Seren (Étoile filante). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: bow(m, x, z), skin="skin_pale", hair="hair_silver", ears="elf", wings="feather_white", hat=('circlet', 'gold'), glow="glow_gold", eyes="glow_gold", hair_style="long")
