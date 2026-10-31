"""Grand amas de cristaux (violet) sur socle rocheux."""
import math
from props._common import glow_moss

EXTENT = 2.6


def build(m):
    m.ao_height = 0.6
    m.rock((0, 0, 0), (0.8, 0.7, 0.35), "rock", subdiv=2, rough=0.12)
    m.crystal_cluster((0, 0, 0.2), 1.5, "crystal_violet", 7)
    for i in range(3):
        a = math.tau * i / 3 + 0.6
        m.crystal_cluster((math.cos(a) * 0.75, math.sin(a) * 0.65, 0.0), 0.55, "crystal_violet", 4)
    glow_moss(m, 0, 0, 0.0, 1.1, 10, "glow_teal" if "violet" != "violet" else "glow_violet")
