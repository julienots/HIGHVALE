"""Mineur de cristaux : casque à lampe, pioche ; rapporte des cristaux abyssaux."""
from characters._villager import villager, pickaxe, carry_crystal

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "cloth_blue", trousers="cloth_cream", skin="skin_dark", hair="hair_brown", hat="helmet", tool=pickaxe, carry=carry_crystal)
