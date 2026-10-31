"""Héros : Tibérius (Paladin de l'Aube). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "gold", "cloth_white", weapon=lambda m, x, z: mace(m, x, z, "gold"), offhand=lambda m, x, z: shield(m, x, z, "cloth_white", "gold"), hair="hair_white", beard=True, armor="gold", pauldrons="gold", helmet="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", hair_style="short")
