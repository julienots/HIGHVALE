"""Cristaux affleurants (1 case) : rare, peut contenir des prismes."""
import math

EXTENT = 1.2


def build(m):
    m.ao_height = 0.4
    m.rock((0, 0, 0), (0.3, 0.27, 0.12), "rock", subdiv=1)
    m.crystal_cluster((0, 0, 0.05), 0.5, "crystal", 5)
    m.crystal((0.2, 0.12, 0.02), 0.16, 0.04, "crystal_violet", tilt=(20, -25))
