"""Construit les modèles 3D de HIGHVALE et les exporte en .glb.

Utilisation (module bpy ou Blender en ligne de commande) :
    python tools/blender/build_models.py [identifiants…] [--preview DOSSIER]
    blender -b -P tools/blender/build_models.py -- [identifiants…] [--preview DOSSIER]

Chaque fichier models/<id>.py expose build(m: Model). Le résultat est écrit dans
assets/models/buildings/<id>.glb ; --preview rend aussi une image Cycles.
"""
import importlib
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import hv_kit  # noqa: E402

OUT_DIR = os.path.join(ROOT, "assets", "models", "buildings")


def render_preview(path, extent):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 560
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.12, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
    scene.world = world
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 1.5 + 0.6
    cam = bpy.data.objects.new("cam", cam_data)
    pitch, yaw, dist = math.radians(40), math.radians(45), 30
    d = Vector((math.cos(pitch) * math.sin(yaw), -math.cos(pitch) * math.cos(yaw), math.sin(pitch)))
    target = Vector((0, 0, extent * 0.3))
    cam.location = target + d * dist
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.2
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    scene.collection.objects.link(sun)
    floor = bpy.data.meshes.new("floor")
    floor.from_pydata([(-20, -20, 0), (20, -20, 0), (20, 20, 0), (-20, 20, 0)], [], [(0, 1, 2, 3)])
    fo = bpy.data.objects.new("floor", floor)
    fm = bpy.data.materials.new("floor")
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.09, 0.08, 1)
    floor.materials.append(fm)
    scene.collection.objects.link(fo)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def hide_above_tier(tier):
    import re
    for o in bpy.context.scene.objects:
        mt = re.search(r"(?:^|_)t(\d)(?:_|$)", o.name)
        if mt and int(mt.group(1)) > tier:
            o.hide_render = True


def main(argv):
    preview = None
    tier = 3
    if "--tier" in argv:
        i = argv.index("--tier")
        tier = int(argv[i + 1])
        argv = argv[:i] + argv[i + 2:]
    if "--preview" in argv:
        i = argv.index("--preview")
        preview = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    ids = argv or sorted(f[:-3] for f in os.listdir(os.path.join(HERE, "models")) if f.endswith(".py") and not f.startswith("_"))
    os.makedirs(OUT_DIR, exist_ok=True)
    for model_id in ids:
        mod = importlib.import_module("models." + model_id)
        m = hv_kit.Model(seed=sum(map(ord, model_id)))
        mod.build(m)
        faces = m.export(os.path.join(OUT_DIR, model_id + ".glb"))
        print("%-22s %6d faces" % (model_id, faces))
        if preview:
            os.makedirs(preview, exist_ok=True)
            hide_above_tier(tier)
            render_preview(os.path.join(preview, "%s_t%d.png" % (model_id, tier)), getattr(mod, "EXTENT", 3.0))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(args)
