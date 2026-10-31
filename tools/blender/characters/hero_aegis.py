"""Héros : Égide (Protectrice divine). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "gold", "cloth_white", weapon=lambda m, x, z: spear(m, x, z, "gold"), offhand=lambda m, x, z: shield(m, x, z, "cloth_white", "gold"), skin="skin_pale", hair="hair_blond", wings="feather_white", crown="gold", armor="gold", pauldrons="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", hair_style="long")
