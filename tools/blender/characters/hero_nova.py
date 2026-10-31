"""Héros : Nova (Étincelle stellaire). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_blue", weapon=lambda m, x, z: wand(m, x, z, "glow_gold"), offhand=lambda m, x, z: orb(m, x, z, "glow_gold"), skin="skin_dark", hair="hair_white", hat=('wizard', 'cloth_white'), eyes="glow_gold", glow="glow_gold", hair_style="twintails")
