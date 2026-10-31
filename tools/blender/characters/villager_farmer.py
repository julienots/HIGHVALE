"""Cultivatrice : chapeau de paille, tablier, faucille ; rapporte du bois fongique."""
from characters._villager import villager, sickle, carry_log

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "cloth_green", trousers="cloth_brown", hair="hair_brown", hat="straw", tool=sickle, carry=carry_log, apron="cloth_cream")
