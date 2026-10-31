"""Vitalia, Déesse de la vie."""
from characters._hero import *  # noqa: F401,F403
from characters._god import halo, wings

EXTENT = 0.32
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "cloth_white", skin="skin_pale", hair="hair_blond", hair_style="long", eyes="eye_glow", crown="moss",
         cape="cloth_white", skirt="cloth_green", glow="glow_gold",
         weapon=lambda m, x, z: staff(m, x, z, orb="glow_gold", top="moss"), offhand=lambda m, x, z: m.sphere(0.04, (x, -0.04, z + 0.03), "glow_teal", seg=10, rings=6))
    halo(m, "glow_gold")
    wings(m, "cloth_white")
    m.light((0, -0.2, 0.4), "ffd84a", 0.8, 2.0)
