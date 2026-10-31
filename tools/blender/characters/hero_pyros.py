"""Pyros, Dieu du feu primordial."""
from characters._hero import *  # noqa: F401,F403
from characters._god import halo

EXTENT = 0.32
FLAT_PALETTE = True


def build(m):
    hero(m, "scale_red", "cloth_black", skin="skin_dark", hair="fire", hair_style="spiky", eyes="fire", beard=False,
         armor="gold", pauldrons="gold", cape="cloth_red", glow="fire", weapon=greataxe, offhand=flame_hand)
    halo(m, "fire", radius=0.15)
    m.light((0, -0.2, 0.4), "ff7a30", 0.9, 2.0)
