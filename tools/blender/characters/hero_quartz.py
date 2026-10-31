"""Héros : Quartz (Golem apprivoisé). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "crystal", "steel_dark", weapon=lambda m, x, z: gauntlet(m, x, z, "crystal"), offhand=lambda m, x, z: gauntlet(m, x, z, "crystal"), skin="skin_blue", eyes="crystal", pauldrons="crystal", hair_style="bald")
