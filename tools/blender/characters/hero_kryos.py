"""Kryos, Dieu des cristaux."""
from characters._hero import *  # noqa: F401,F403
from characters._god import halo

EXTENT = 0.32
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "steel", skin="skin_blue", hair="hair_silver", hair_style="long", eyes="eye_glow", crown="crystal",
         armor="steel", pauldrons="crystal", cape="cloth_teal", skirt="cloth_blue", glow="rune",
         weapon=lambda m, x, z: staff(m, x, z, orb="crystal", top="crystal"))
    halo(m, "rune")
    for sx in (-1, 1):
        with m.anim("shard%d" % (sx + 1), (sx * 0.22, 0, 0.32), spin=("Y", 60), bob=0.03):
            m.crystal((sx * 0.22, 0, 0.28), 0.12, 0.03, "crystal")
    m.light((0, -0.2, 0.4), "7fdcff", 0.8, 2.0)
