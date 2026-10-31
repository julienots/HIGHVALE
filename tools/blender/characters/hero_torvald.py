"""Héros : Torvald (Berserker du nord). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "fur_grey", "leather", weapon=lambda m, x, z: greataxe(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "iron"), skin="skin_pale", hair="hair_blond", beard=True, hat=('horned', 'iron'), pauldrons="fur_grey", hair_style="braids")
