"""Héros : Goliath (Géant de pierre). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "rock", "rock_light", weapon=lambda m, x, z: hammer_big(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "rock"), skin="rock", eyes="glow_gold", armor="rock_light", pauldrons="rock", hair_style="bald")
