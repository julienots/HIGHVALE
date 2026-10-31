"""Héros : Silas (Chasseur de primes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_black", weapon=lambda m, x, z: crossbow(m, x, z), offhand=lambda m, x, z: dagger(m, x, z), hair="hair_brown", hat=('wide', 'leather'), scarf="cloth_red", mask="cloth_red", hair_style="short")
