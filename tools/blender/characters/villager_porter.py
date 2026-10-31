"""Porteur : casquette, sac à dos ; transporte l'or de la Trésorerie."""
from characters._villager import villager, carry_gold

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "cloth_red", trousers="cloth_brown", hair="hair_white", hat="cap", carry=carry_gold, backpack=True, beard=True)
