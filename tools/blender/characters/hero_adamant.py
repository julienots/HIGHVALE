"""Héros : Adamant (Colosse de diamant). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "crystal", "crystal_teal", weapon=lambda m, x, z: hammer_big(m, x, z), offhand=lambda m, x, z: shield(m, x, z, "crystal_teal", "crystal"), skin="skin_blue", eyes="glow_gold", armor="crystal", pauldrons="crystal", crown="crystal", glow="rune", hair_style="bald")
