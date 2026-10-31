"""Héros : Croc (Chef de meute). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "fur_grey", "leather", weapon=lambda m, x, z: sword(m, x, z, "steel"), offhand=lambda m, x, z: claws(m, x, z, "steel"), hair="fur_grey", ears="fur_grey", tail="fur_grey", armor="iron", pauldrons="fur_grey", cape="cloth_red", hair_style="mane")
