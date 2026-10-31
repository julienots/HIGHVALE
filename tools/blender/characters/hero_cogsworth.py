"""Héros : Rouage (Automate gardien). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "bronze", "iron", weapon=lambda m, x, z: gauntlet(m, x, z, "bronze"), offhand=lambda m, x, z: shield(m, x, z, "bronze", "gold"), skin="bronze", eyes="glow_gold", armor="bronze", pauldrons="bronze", helmet="bronze", glow="glow_gold", hair_style="bald")
