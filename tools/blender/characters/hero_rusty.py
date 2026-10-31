"""Héros : Rouille (Robot de chantier). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "iron", "bronze", weapon=lambda m, x, z: pickaxe(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "iron"), skin="iron", eyes="fire", armor="iron", pauldrons="bronze", hair_style="bald")
