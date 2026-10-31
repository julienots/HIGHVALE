"""Héros : Cassia (Chronomancienne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "gold", weapon=lambda m, x, z: staff(m, x, z, "crystal_violet", "gold"), offhand=lambda m, x, z: orb(m, x, z, "glow_violet"), skin="skin_pale", hair="hair_silver", hat=('circlet', 'gold'), cape="cloth_purple", eyes="glow_violet", glow="glow_violet", hair_style="long")
