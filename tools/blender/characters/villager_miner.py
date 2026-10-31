"""Mineur : casque à lampe, pioche, barbe ; rapporte de la pierre ou des cristaux."""
from characters._villager import villager, pickaxe, carry_stone

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    villager(m, "cloth_blue", trousers="cloth_brown", hair="hair_red", hat="helmet", tool=pickaxe, carry=carry_stone, beard=True)
