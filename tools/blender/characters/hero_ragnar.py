"""Héros : Ragnar (Roi des berserkers). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "fur_brown", "leather", weapon=lambda m, x, z: greataxe(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "steel_dark"), skin="skin_pale", hair="hair_red", beard=True, hat=('horned', 'steel_dark'), pauldrons="fur_brown", cape="cloth_red", glow="fire", eyes="fire", hair_style="braids")
