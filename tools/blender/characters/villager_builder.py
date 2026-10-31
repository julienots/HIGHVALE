"""Bâtisseur : casque orange, marteau, tablier de cuir."""
from characters._villager import villager, hammer

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "cloth_orange", trousers="cloth_blue", skin="skin_dark", hair="hair_brown", hat="builder", tool=hammer, apron="leather")
