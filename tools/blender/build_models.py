"""Construit les modèles 3D de HIGHVALE et les exporte en .glb.

Utilisation (module bpy ou Blender en ligne de commande) :
    python tools/blender/build_models.py [identifiants…] [--preview DOSSIER] [--tier N]
    blender -b -P tools/blender/build_models.py -- [identifiants…] [--preview DOSSIER]

Chaque fichier models/<id>.py (bâtiments), props/<id>.py (décors) ou
characters/<id>.py (habitants) expose build(m: Model). Le résultat est écrit dans
assets/models/<catégorie>/<id>.glb ; --preview rend aussi une image Cycles.
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

# Dossier source -> dossier d'export
CATEGORIES = {
    "models": os.path.join(ROOT, "assets", "models", "buildings"),
    "props": os.path.join(ROOT, "assets", "models", "props"),
    "characters": os.path.join(ROOT, "assets", "models", "characters"),
}


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


def render_portrait(path, extent):
    """Portrait de carte : vue de trois quarts face, fond transparent."""
    scene = bpy.context.scene
    # Les émissions fortes (feu, lave) virent au pastel dans Cycles : on les
    # atténue pour le portrait seulement (le jeu garde les valeurs du modèle).
    for mat in bpy.data.materials:
        if mat.node_tree:
            for node in mat.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED" and node.inputs["Emission Strength"].default_value > 2.0:
                    node.inputs["Emission Strength"].default_value = 0.9
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 384
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    world = bpy.data.worlds.new("pw")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.6, 0.8, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    scene.world = world
    cam_data = bpy.data.cameras.new("pcam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 2.4
    cam = bpy.data.objects.new("pcam", cam_data)
    yaw, pitch = math.radians(-28), math.radians(12)
    d = Vector((math.sin(-yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    target = Vector((0, 0, extent * 1.05))
    cam.location = target + d * 10
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    for name, energy, rot in (("key", 4.0, (50, 0, -35)), ("rim", 3.0, (60, 0, 160))):
        lo = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
        lo.data.energy = energy
        lo.rotation_euler = [math.radians(a) for a in rot]
        scene.collection.objects.link(lo)
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
    portraits = "--portraits" in argv
    if portraits:
        argv = [a for a in argv if a != "--portraits"]
    if "--tier" in argv:
        i = argv.index("--tier")
        tier = int(argv[i + 1])
        argv = argv[:i] + argv[i + 2:]
    if "--preview" in argv:
        i = argv.index("--preview")
        preview = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    index = {}
    for cat in CATEGORIES:
        for f in sorted(os.listdir(os.path.join(HERE, cat))):
            if f.endswith(".py") and not f.startswith("_"):
                index[f[:-3]] = cat
    ids = argv or list(index)
    for model_id in ids:
        cat = index[model_id]
        mod = importlib.import_module("%s.%s" % (cat, model_id))
        m = hv_kit.Model(seed=sum(map(ord, model_id)), flat_palette=getattr(mod, "FLAT_PALETTE", False))
        mod.build(m)
        os.makedirs(CATEGORIES[cat], exist_ok=True)
        faces = m.export(os.path.join(CATEGORIES[cat], model_id + ".glb"))
        print("%-22s %6d faces" % (model_id, faces))
        if portraits and cat == "characters" and (model_id.startswith("hero_") or model_id.startswith("monster_")):
            out = os.path.join(ROOT, "assets", "portraits", model_id + ".png")
            os.makedirs(os.path.dirname(out), exist_ok=True)
            render_portrait(out, getattr(mod, "EXTENT", 0.3))
        if preview:
            os.makedirs(preview, exist_ok=True)
            hide_above_tier(tier)
            render_preview(os.path.join(preview, "%s_t%d.png" % (model_id, tier)), getattr(mod, "EXTENT", 3.0))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(args)
