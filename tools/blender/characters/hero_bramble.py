"""Héros : Ronce (Gardien des bosquets). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "bark", "leaf_dark", weapon=lambda m, x, z: mace(m, x, z, "bark"), offhand=lambda m, x, z: shield(m, x, z, "leaf", "bark"), skin="skin_green", hair="leaf", eyes="glow_teal", armor="bark", pauldrons="leaf_dark", hair_style="mane")
