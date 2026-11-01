"""Régénère toute la bande-son de HIGHVALE (musiques, ambiance, jingles et
effets sonores), entièrement synthétisée avec numpy et scipy.

    python3 tools/audio/make_audio.py

Voir synth.py (instruments, réverbération, mastering), compose.py (musiques)
et sfx.py (effets sonores).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
for script in ("compose.py", "sfx.py"):
    subprocess.run([sys.executable, os.path.join(HERE, script)], check=True, cwd=HERE)
