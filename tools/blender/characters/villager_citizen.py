"""Habitante : chignon, tenue violette ; flâne dans la cité."""
from characters._villager import villager

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "roof_violet", trousers="cloth_cream", skin="skin", hair="hair_brown", hat="bun", apron="cloth_cream")
