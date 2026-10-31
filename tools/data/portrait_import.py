"""Règle l'import des portraits : compression VRAM (ETC2/ASTC sur mobile),
256 px maximum, mipmaps. Évite ~100 Mo de textures non compressées pour la
collection complète. À lancer après un premier import Godot des nouveaux
portraits : python3 tools/data/portrait_import.py"""
import glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SET = {"compress/mode": "2", "mipmaps/generate": "true", "process/size_limit": "256"}
n = 0
for p in glob.glob(os.path.join(ROOT, "assets", "portraits", "*.png.import")):
    s = open(p).read()
    t = s
    for k, v in SET.items():
        t = re.sub(r"^%s=.*$" % re.escape(k), "%s=%s" % (k, v), t, flags=re.M)
    if t != s:
        open(p, "w").write(t)
        n += 1
print(n, "portraits mis à jour")
