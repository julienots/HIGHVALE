"""Boîte à outils de modélisation HIGHVALE pour Blender (bpy).

Chaque modèle est assemblé à partir de pièces biseautées (pierres, planches,
tuiles, cristaux…) fusionnées par matériau. Les couleurs de sommets ajoutent
des variations par pièce et une occlusion ambiante au pied des bâtiments.

Conventions d'export glTF (lues par Godot, voir src/city/model_rig.gd) :
  - repère Blender : Z en haut, façade principale vers -Y (= +Z dans Godot) ;
  - 1 unité = 1 case de la grille, origine au centre de l'emprise, sol à z = 0 ;
  - nom de nœud découpé en jetons par « _ » :
      tN        visible à partir du palier N (niveaux 1-2 = 0, 3-4 = 1, 5-6 = 2, 7+ = 3)
      spinY35   rotation continue de 35°/s autour de l'axe Y de Godot
      bob8      flottement vertical de 0,08 unité
      light     repère de lumière : light_RRGGBB_e14_r50 (énergie 1,4, portée 5,0)
"""
import math
import random
from contextlib import contextmanager

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector


def lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# Palette commune : nom -> (couleur sRGB, rugosité, métal, émission, intensité)
PALETTE = {
    "stone": ("9aa0b2", 0.85, 0.0, None, 0),
    "stone_dark": ("6d7389", 0.9, 0.0, None, 0),
    "stone_warm": ("c9b596", 0.85, 0.0, None, 0),
    "marble": ("ddd4c2", 0.45, 0.0, None, 0),
    "plaster": ("efe1c4", 0.9, 0.0, None, 0),
    "wood": ("a8703f", 0.8, 0.0, None, 0),
    "wood_dark": ("6e4628", 0.85, 0.0, None, 0),
    "wood_light": ("c8945a", 0.8, 0.0, None, 0),
    "roof_blue": ("3b5ec8", 0.55, 0.0, None, 0),
    "roof_red": ("bf4630", 0.55, 0.0, None, 0),
    "roof_slate": ("4a4f6a", 0.6, 0.0, None, 0),
    "roof_teal": ("2a8f8a", 0.55, 0.0, None, 0),
    "gold": ("ffbe3b", 0.28, 1.0, None, 0),
    "bronze": ("b97a3a", 0.35, 0.9, None, 0),
    "iron": ("515868", 0.45, 0.85, None, 0),
    "cloth_blue": ("2d4db8", 0.95, 0.0, None, 0),
    "cloth_red": ("c23a3a", 0.95, 0.0, None, 0),
    "cloth_cream": ("e8dcc0", 0.95, 0.0, None, 0),
    "rock": ("6a6385", 0.95, 0.0, None, 0),
    "rock_light": ("8a84a3", 0.95, 0.0, None, 0),
    "earth": ("4a3528", 1.0, 0.0, None, 0),
    "moss": ("4f9a4a", 0.95, 0.0, None, 0),
    "dark": ("120e18", 1.0, 0.0, None, 0),
    "crystal": ("2fa8ff", 0.08, 0.0, "62c8ff", 2.2),
    "crystal_violet": ("8a5cff", 0.08, 0.0, "b49cff", 2.2),
    "crystal_teal": ("1ad6c0", 0.08, 0.0, "7ff5e4", 2.2),
    "window": ("ffcf6a", 0.5, 0.0, "ffb648", 3.0),
    "flame": ("ffa030", 0.5, 0.0, "ff8a1f", 7.0),
    "rune": ("7fe8ff", 0.4, 0.0, "62d8ff", 4.0),
    "mushroom_teal": ("3fd6c0", 0.6, 0.0, None, 0),
    "mushroom_violet": ("8a64ff", 0.6, 0.0, None, 0),
    "mushroom_pink": ("ff6ad5", 0.6, 0.0, None, 0),
    "mushroom_stem": ("efe6d2", 0.8, 0.0, None, 0),
    "roof_violet": ("6a44c8", 0.55, 0.0, None, 0),
    "straw": ("e0c070", 0.95, 0.0, None, 0),
    "water": ("2a8fd0", 0.05, 0.0, "1a6fb0", 0.6),
    "glass": ("bff6ff", 0.05, 0.0, None, 0),
    "brew_violet": ("b464ff", 0.3, 0.0, "a050ff", 3.0),
    "brew_green": ("5bff8a", 0.3, 0.0, "3ae070", 3.0),
    "glow_gold": ("fff1a8", 0.4, 0.0, "ffd84a", 4.0),
    "skin": ("f2c39c", 0.7, 0.0, None, 0),
    "skin_dark": ("a8714a", 0.7, 0.0, None, 0),
    "hair_brown": ("5a3a24", 0.8, 0.0, None, 0),
    "hair_red": ("b8502a", 0.8, 0.0, None, 0),
    "hair_white": ("e8e4dc", 0.8, 0.0, None, 0),
    "cloth_green": ("4f8a3a", 0.95, 0.0, None, 0),
    "cloth_brown": ("8a5a34", 0.95, 0.0, None, 0),
    "cloth_orange": ("e8862a", 0.95, 0.0, None, 0),
    "leather": ("6a4228", 0.8, 0.0, None, 0),
    "helmet_yellow": ("f2b62a", 0.45, 0.0, None, 0),
    "palette": ("ffffff", 0.8, 0.0, None, 0),
    "steel": ("b8c2d4", 0.35, 0.0, None, 0),
    "steel_dark": ("5a6478", 0.4, 0.0, None, 0),
    "cloth_purple": ("5a2d8a", 0.95, 0.0, None, 0),
    "cloth_black": ("26222e", 0.95, 0.0, None, 0),
    "cloth_white": ("efe9df", 0.95, 0.0, None, 0),
    "cloth_teal": ("1f8f8a", 0.95, 0.0, None, 0),
    "hair_black": ("221c26", 0.8, 0.0, None, 0),
    "hair_blond": ("f0c860", 0.8, 0.0, None, 0),
    "hair_silver": ("c8d0e0", 0.8, 0.0, None, 0),
    "hair_blue": ("3a6ad8", 0.8, 0.0, None, 0),
    "skin_pale": ("f6dcc8", 0.7, 0.0, None, 0),
    "skin_blue": ("8ab8e0", 0.7, 0.0, None, 0),
    "skin_green": ("7ab86a", 0.7, 0.0, None, 0),
    "eye_glow": ("fff6c0", 0.4, 0.0, "ffe680", 4.0),
    "fire": ("ff7a20", 0.4, 0.0, "ff5a10", 5.0),
    "shadow_glow": ("a050ff", 0.4, 0.0, "8030ff", 4.0),
    "slime": ("46e0c8", 0.2, 0.0, None, 0),
    "fur_violet": ("5b3c8c", 0.95, 0.0, None, 0),
    "fur_night": ("2c2c5a", 0.95, 0.0, None, 0),
    "scale_red": ("d8452a", 0.6, 0.0, None, 0),
    "scale_belly": ("f2c070", 0.7, 0.0, None, 0),
    "membrane": ("8a5aa8", 0.9, 0.0, None, 0),
    "eel_blue": ("2a6ad0", 0.4, 0.0, None, 0),
    "leaf": ("4fa84a", 0.9, 0.0, None, 0),
    "leaf_dark": ("2f7a3a", 0.9, 0.0, None, 0),
    "leaf_autumn": ("e8a23a", 0.9, 0.0, None, 0),
    "bark": ("7a5236", 0.9, 0.0, None, 0),
    "grass": ("6ab84a", 0.95, 0.0, None, 0),
    "glow_teal": ("a8fff2", 0.5, 0.0, "6ff5e0", 2.5),
    "glow_violet": ("d8c8ff", 0.5, 0.0, "b49cff", 2.5),
    "glow_pink": ("ffc8f0", 0.5, 0.0, "ff8ae0", 2.5),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _material(name):
    m = bpy.data.materials.get(name)
    if m:
        return m
    col, rough, metal, emit, strength = PALETTE[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*lin(col), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*lin(emit), 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    if name == "glass":
        bsdf.inputs["Alpha"].default_value = 0.35
        m.surface_render_method = "BLENDED"
    # La couleur de sommet module la couleur de base (exportée en COLOR_0).
    attr = m.node_tree.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    mix = m.node_tree.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.inputs[6].default_value = (*lin(col), 1.0)
    m.node_tree.links.new(attr.outputs["Color"], mix.inputs[7])
    m.node_tree.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return m


def _bevel(bm, width, segments=1):
    if width <= 0:
        return
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces), offset=width,
                    offset_type="OFFSET", segments=segments, profile=0.5, affect="EDGES",
                    clamp_overlap=True)


def _mat4(loc, rot, scale=(1, 1, 1)):
    return Matrix.LocRotScale(Vector(loc), Euler([math.radians(a) for a in rot]), Vector(scale))


class Model:
    def __init__(self, seed=1, flat_palette=False):
        """flat_palette : toutes les couleurs non émissives passent par un seul
        matériau « palette » (couleur portée par les sommets) — idéal pour les
        personnages animés, qui ne peuvent pas être fusionnés entre eux."""
        reset_scene()
        self.flat_palette = flat_palette
        self.rng = random.Random(seed)
        self.acc = {}  # (groupe, matériau) -> (bmesh, couche couleur)
        self.group = "t0"
        self.pivots = {}  # groupe -> pivot
        self.lights = []
        self.ao_height = 0.7

    # --- Groupes ----------------------------------------------------------
    @contextmanager
    def tier(self, n):
        old = self.group
        self.group = "t%d" % n
        yield
        self.group = old

    @contextmanager
    def anim(self, name, pivot, spin=None, bob=0.0, tier=None):
        """Pièces animées : spin = ("Y", 35) en axes Godot, bob en unités."""
        old = self.group
        t = tier if tier is not None else int(old[1:]) if old.startswith("t") else 0
        tokens = [name, "t%d" % t]
        if spin:
            tokens.append("spin%s%d" % (spin[0], spin[1]))
        if bob:
            tokens.append("bob%d" % round(bob * 100))
        self.group = "_".join(tokens)
        self.pivots[self.group] = Vector(pivot)
        yield
        self.group = old

    def light(self, pos, color, energy=1.4, rng=5.0, tier=0):
        self.lights.append((Vector(pos), color, energy, rng, tier))

    def jitter(self, amount=0.08):
        return 1.0 - amount + self.rng.random() * amount * 2

    # --- Fusion -----------------------------------------------------------
    def _target(self, mat):
        key = (self.group, mat)
        if key not in self.acc:
            bm = bmesh.new()
            self.acc[key] = (bm, bm.loops.layers.color.new("Col"))
        return self.acc[key]

    def add(self, src, mat, matrix, tint=None, smooth=None):
        if tint is None:
            tint = self.jitter(0.06)
        if not isinstance(tint, (tuple, list)):
            tint = (tint, tint, tint)
        if self.flat_palette and PALETTE[mat][3] is None:
            # Couche de couleur en octets : Blender l'interprète déjà comme sRGB.
            h = PALETTE[mat][0]
            base = tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
            tint = (tint[0] * base[0], tint[1] * base[1], tint[2] * base[2])
            mat = "palette"
        bm, col = self._target(mat)
        src.normal_update()
        vmap = {v: bm.verts.new(matrix @ v.co) for v in src.verts}
        for f in src.faces:
            try:
                nf = bm.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                continue
            if smooth == "sides":
                nf.smooth = abs(f.normal.z) < 0.7
            else:
                nf.smooth = bool(smooth)
            for loop in nf.loops:
                loop[col] = (tint[0], tint[1], tint[2], 1.0)
        src.free()

    # --- Primitives -------------------------------------------------------
    def box(self, size, loc, mat, rot=(0, 0, 0), bevel=0.02, tint=None):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
        _bevel(bm, min(bevel, min(size) * 0.45))
        self.add(bm, mat, _mat4(loc, rot), tint)

    def cyl(self, r, h, loc, mat, r2=None, seg=12, rot=(0, 0, 0), bevel=0.0, tint=None, smooth="sides", scale=(1, 1, 1)):
        """Cylindre ou tronc de cône posé sur loc (base)."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r,
                              radius2=r if r2 is None else r2, depth=h)
        bmesh.ops.translate(bm, vec=Vector((0, 0, h / 2)), verts=bm.verts)
        if r2 == 0:
            bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        _bevel(bm, bevel)
        self.add(bm, mat, _mat4(loc, rot, scale), tint, smooth)

    def sphere(self, r, loc, mat, seg=16, rings=8, scale=(1, 1, 1), hemi=False, rot=(0, 0, 0), tint=None, smooth=True):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
        if hemi:
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -1e-4], context="VERTS")
            edges = [e for e in bm.edges if e.is_boundary]
            if edges:
                bmesh.ops.edgeloop_fill(bm, edges=edges)
        self.add(bm, mat, _mat4(loc, rot, scale), tint, smooth)

    def torus(self, R, r, loc, mat, rot=(0, 0, 0), seg=24, rseg=8, tint=None, arc=360.0):
        bm = bmesh.new()
        rings = []
        full = arc >= 360.0
        n = seg if full else seg + 1
        for i in range(n):
            a = math.radians(arc) * i / seg
            c = Vector((math.cos(a) * R, math.sin(a) * R, 0))
            ring = []
            for j in range(rseg):
                b = 2 * math.pi * j / rseg
                d = Vector((math.cos(a), math.sin(a), 0)) * math.cos(b) * r + Vector((0, 0, math.sin(b) * r))
                ring.append(bm.verts.new(c + d))
            rings.append(ring)
        for i in range(seg if full else seg):
            a, b = rings[i], rings[(i + 1) % n]
            for j in range(rseg):
                bm.faces.new((a[j], b[j], b[(j + 1) % rseg], a[(j + 1) % rseg]))
        self.add(bm, mat, _mat4(loc, rot), tint, True)

    def poly(self, verts, faces, loc, mat, rot=(0, 0, 0), tint=None, smooth=False, scale=(1, 1, 1)):
        bm = bmesh.new()
        vs = [bm.verts.new(Vector(v)) for v in verts]
        for f in faces:
            try:
                bm.faces.new([vs[i] for i in f])
            except ValueError:
                # Face déjà présente (face arrière) : sommets dupliqués.
                bm.faces.new([bm.verts.new(vs[i].co) for i in f])
        self.add(bm, mat, _mat4(loc, rot, scale), tint, smooth)

    def prism(self, w, d, h, loc, mat, rot=(0, 0, 0), tint=None):
        """Prisme triangulaire (pignon) : faîtage le long de X."""
        v = [(-w / 2, -d / 2, 0), (w / 2, -d / 2, 0), (w / 2, d / 2, 0), (-w / 2, d / 2, 0), (-w / 2, 0, h), (w / 2, 0, h)]
        f = [(0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5), (0, 3, 2, 1)]
        self.poly(v, f, loc, mat, rot, tint)

    def rock(self, loc, scale, mat="rock", rot_z=None, subdiv=1, rough=0.22, tint=None):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
        for v in bm.verts:
            v.co *= 1.0 - rough + self.rng.random() * rough * 2
            if v.co.z < 0:
                v.co.z *= 0.35
        self.add(bm, mat, _mat4(loc, (0, 0, self.rng.uniform(0, 360) if rot_z is None else rot_z), scale), tint, False)

    # --- Composants -------------------------------------------------------
    def crystal(self, loc, h, r, mat="crystal", tilt=(0, 0), rz=0.0, tint=None):
        bm = bmesh.new()
        n = 6
        top = h * 0.72
        ring_b = [bm.verts.new((math.cos(2 * math.pi * i / n) * r, math.sin(2 * math.pi * i / n) * r, 0)) for i in range(n)]
        ring_t = [bm.verts.new((math.cos(2 * math.pi * i / n) * r * 0.92, math.sin(2 * math.pi * i / n) * r * 0.92, top)) for i in range(n)]
        tip = bm.verts.new((r * 0.12, -r * 0.08, h))
        bm.faces.new(list(reversed(ring_b)))
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((ring_b[i], ring_b[j], ring_t[j], ring_t[i]))
            bm.faces.new((ring_t[i], ring_t[j], tip))
        self.add(bm, mat, _mat4(loc, (tilt[0], tilt[1], rz)), tint or self.jitter(0.12), False)

    def crystal_cluster(self, loc, size, mat="crystal", count=5):
        x, y, z = loc
        self.crystal((x, y, z - 0.05), size * 1.25, size * 0.2, mat, (0, 0), self.rng.uniform(0, 60))
        for i in range(count - 1):
            a = 2 * math.pi * i / (count - 1) + self.rng.uniform(-0.3, 0.3)
            d = size * self.rng.uniform(0.14, 0.26)
            tilt = self.rng.uniform(18, 38)
            self.crystal((x + math.cos(a) * d, y + math.sin(a) * d, z - 0.05), size * self.rng.uniform(0.45, 0.85),
                         size * self.rng.uniform(0.1, 0.16), mat,
                         (-math.sin(a) * tilt, math.cos(a) * tilt), self.rng.uniform(0, 60))

    def flagstone_plinth(self, w, d, h=0.18, mat="stone", curb="stone_dark", tile=0.5):
        """Socle en dalles irrégulières entouré d'une bordure de blocs."""
        self.box((w, d, h * 0.7), (0, 0, h * 0.35), curb, bevel=0.03)
        nx, ny = max(1, round((w - 0.2) / tile)), max(1, round((d - 0.2) / tile))
        tw, td = (w - 0.2) / nx, (d - 0.2) / ny
        for i in range(nx):
            for j in range(ny):
                hh = 0.05 + self.rng.random() * 0.015
                self.box((tw - 0.03, td - 0.03, hh), (-w / 2 + 0.1 + tw * (i + 0.5), -d / 2 + 0.1 + td * (j + 0.5), h * 0.7 + hh / 2),
                         mat, bevel=0.015, tint=self.jitter(0.1))
        # Bordure de blocs
        for side in range(4):
            length = w if side % 2 == 0 else d
            n = max(2, round(length / 0.62))
            seg = length / n
            for k in range(n):
                t = -length / 2 + seg * (k + 0.5)
                if side == 0:
                    p, s = (t, -d / 2 + 0.06, h * 0.75), (seg - 0.03, 0.14, 0.12)
                elif side == 1:
                    p, s = (w / 2 - 0.06, t, h * 0.75), (0.14, seg - 0.03, 0.12)
                elif side == 2:
                    p, s = (t, d / 2 - 0.06, h * 0.75), (seg - 0.03, 0.14, 0.12)
                else:
                    p, s = (-w / 2 + 0.06, t, h * 0.75), (0.14, seg - 0.03, 0.12)
                self.box(s, p, curb, bevel=0.025, tint=self.jitter(0.12))
        return h * 0.7 + 0.055

    def brick_wall(self, p0, p1, z0, height, thick=0.22, mat="stone", course=0.18, brick=0.36, bevel=0.025):
        """Mur de pierres taillées entre p0 et p1 (plan XY), assises décalées."""
        p0, p1 = Vector((p0[0], p0[1], 0)), Vector((p1[0], p1[1], 0))
        length = (p1 - p0).length
        ang = math.degrees(math.atan2(p1.y - p0.y, p1.x - p0.x))
        rows = max(1, round(height / course))
        ch = height / rows
        for r in range(rows):
            off = (brick / 2) if r % 2 else 0.0
            t = -off
            while t < length - 1e-3:
                a, b = max(t, 0.0), min(t + brick * self.rng.uniform(0.8, 1.2), length)
                if b - a > 0.05:
                    mid = p0 + (p1 - p0) * ((a + b) / 2 / length)
                    self.box((b - a - 0.02, thick * self.rng.uniform(0.94, 1.0), ch - 0.02), (mid.x, mid.y, z0 + ch * (r + 0.5)),
                             mat, rot=(0, 0, ang), bevel=bevel, tint=self.jitter(0.12))
                t = b

    def gable_roof(self, center, w, d, h, mat="roof_blue", overhang=0.18, rows=6, ridge_mat=None, rot_z=0.0, gable="wood_dark"):
        """Toit à deux pans couvert de rangées de tuiles ; faîtage le long de X local."""
        cx, cy, cz = center
        rz = math.radians(rot_z)
        rotm = Matrix.Rotation(rz, 4, "Z")
        half = d / 2 + overhang
        slope = math.atan2(h, d / 2)
        slen = math.hypot(half, h * half / (d / 2))
        rw = slen / rows
        for side in (-1, 1):
            for r in range(rows):
                s = (r + 0.5) * rw
                y = side * (half - s * math.cos(slope))
                z = cz - overhang * math.tan(slope) + s * math.sin(slope)
                tilt = -math.degrees(slope) * side
                n_tiles = max(3, round((w + overhang * 2) / 0.32))
                tw = (w + overhang * 2) / n_tiles
                for k in range(n_tiles):
                    x = -(w / 2 + overhang) + tw * (k + 0.5) + (tw / 2 if r % 2 else 0)
                    if abs(x) > w / 2 + overhang - tw * 0.3:
                        continue
                    p = rotm @ Vector((x, y, 0))
                    self.box((tw - 0.025, rw * 1.18, 0.06), (cx + p.x, cy + p.y, z + 0.03), mat,
                             rot=(tilt, 0, rot_z), bevel=0.018, tint=self.jitter(0.1))
        # Faîtage
        ridge = ridge_mat or mat
        p = rotm @ Vector((0, 0, 0))
        self.cyl(0.07, w + overhang * 2.2, (cx - math.cos(rz) * (w / 2 + overhang * 1.1), cy - math.sin(rz) * (w / 2 + overhang * 1.1), cz + h + 0.02),
                 ridge, rot=(0, 90, rot_z), seg=8)
        # Pignons
        for sx in (-1, 1):
            p = rotm @ Vector((sx * (w / 2 - 0.01), 0, 0))
            self.prism(0.08, d, h, (cx + p.x, cy + p.y, cz), gable, rot=(0, 0, rot_z))

    def hip_roof(self, center, size, h, mat="roof_blue", rows=6, hip_mat="gold", tile=0.3):
        """Toit pyramidal à quatre pans couverts de rangées de tuiles."""
        cx, cy, cz = center
        half = size / 2
        slope = math.atan2(h, half)
        rd = math.hypot(half, h) / rows
        for side in range(4):
            rz = side * 90
            rot = Matrix.Rotation(math.radians(rz), 4, "Z")
            for i in range(rows):
                f = (i + 0.5) / rows
                inset = half * f
                length = size - 2 * inset + rd * 0.6
                n = max(1, round(length / tile))
                tw = length / n
                for k in range(n):
                    x = -length / 2 + tw * (k + 0.5) + (tw * 0.5 if i % 2 else 0)
                    if abs(x) > length / 2:
                        continue
                    p = rot @ Vector((x, -(half - inset), 0))
                    self.box((tw - 0.02, rd * 1.2, 0.065), (cx + p.x, cy + p.y, cz + h * f + 0.03), mat,
                             rot=(math.degrees(slope), 0, rz), bevel=0.016, tint=self.jitter(0.1))
        if hip_mat:
            for side in range(4):
                a = math.radians(45 + side * 90)
                d = half * math.sqrt(2)
                self.rod((cx + math.cos(a) * d, cy + math.sin(a) * d, cz + 0.04), (cx, cy, cz + h + 0.04), 0.045, hip_mat)

    def rod(self, p0, p1, r, mat, seg=8, r2=None):
        """Cylindre reliant deux points."""
        a, b = Vector(p0), Vector(p1)
        d = b - a
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r,
                              radius2=r if r2 is None else r2, depth=d.length)
        bmesh.ops.translate(bm, vec=Vector((0, 0, d.length / 2)), verts=bm.verts)
        q = d.normalized().to_track_quat("Z", "Y")
        self.add(bm, mat, Matrix.Translation(a) @ q.to_matrix().to_4x4(), None, "sides")

    def frame_ring(self, size, z, mat="gold", t=0.05):
        """Liseré carré (quatre baguettes) autour d'un niveau."""
        h = size / 2
        self.box((size + t, t, t), (0, -h, z), mat, bevel=0.01)
        self.box((size + t, t, t), (0, h, z), mat, bevel=0.01)
        self.box((t, size + t, t), (-h, 0, z), mat, bevel=0.01)
        self.box((t, size + t, t), (h, 0, z), mat, bevel=0.01)

    def timber_walls(self, cx, cy, w, d, z, h, wall="plaster", beam="wood_dark", bay=0.42):
        """Étage à colombages : enduit, poteaux, sablières et croix de Saint-André."""
        self.box((w, d, h), (cx, cy, z + h / 2), wall, bevel=0.015)
        for sx in (-1, 1):
            for sy in (-1, 1):
                self.box((0.08, 0.08, h + 0.02), (cx + sx * w / 2, cy + sy * d / 2, z + h / 2), beam, bevel=0.012)
        for face in range(4):
            length = w if face % 2 == 0 else d
            n = max(1, round(length / bay))
            def pt(t, off=0.012):
                if face == 0:
                    return (cx + t, cy - d / 2 - off)
                if face == 1:
                    return (cx + w / 2 + off, cy + t)
                if face == 2:
                    return (cx - t, cy + d / 2 + off)
                return (cx - w / 2 - off, cy - t)
            rot = (0, 0, [0, 90, 180, 270][face])
            for hz in (z + 0.04, z + h - 0.04):
                p = pt(0)
                self.box((length, 0.05, 0.06), (p[0], p[1], hz), beam, rot=rot, bevel=0.01)
            for k in range(1, n):
                t = -length / 2 + length * k / n
                p = pt(t)
                self.box((0.05, 0.05, h), (p[0], p[1], z + h / 2), beam, rot=rot, bevel=0.01)
            for k in range(n):
                if k % 2 == 0 and n > 1:
                    t0, t1 = -length / 2 + length * k / n, -length / 2 + length * (k + 1) / n
                    a, b = pt(t0 + 0.04, 0.02), pt(t1 - 0.04, 0.02)
                    self.rod((a[0], a[1], z + 0.07), (b[0], b[1], z + h - 0.07), 0.022, beam, seg=4)

    def mushroom(self, loc, h, cap_r, cap="mushroom_teal", glow="glow_teal", bend=0.15, spots=6, lean=0.0):
        """Champignon géant : pied courbé, chapeau à rebord, lamelles lumineuses, taches."""
        x, y, z = loc
        pts = []
        n = 5
        for i in range(n + 1):
            t = i / n
            pts.append(Vector((x + math.sin(t * 1.6) * bend * math.cos(lean), y + math.sin(t * 1.6) * bend * math.sin(lean), z + h * t)))
        for i in range(n):
            r0 = cap_r * (0.24 - 0.06 * i / n)
            self.rod(pts[i], pts[i + 1] + (pts[i + 1] - pts[i]) * 0.05, r0, "mushroom_stem", seg=10, r2=cap_r * (0.24 - 0.06 * (i + 1) / n))
        self.torus(cap_r * 0.25, cap_r * 0.04, (pts[2].x, pts[2].y, pts[2].z), "mushroom_stem", seg=12, rseg=5)
        top = pts[-1]
        self.sphere(cap_r, (top.x, top.y, top.z - cap_r * 0.08), cap, seg=18, rings=8, hemi=True, scale=(1, 1, 0.62))
        self.torus(cap_r * 0.97, cap_r * 0.07, (top.x, top.y, top.z - cap_r * 0.06), cap, seg=20, rseg=6)
        self.cyl(cap_r * 0.92, 0.03, (top.x, top.y, top.z - cap_r * 0.1), glow, seg=18)
        for i in range(spots):
            a = 2 * math.pi * i / spots + self.rng.uniform(-0.3, 0.3)
            rr = cap_r * self.rng.uniform(0.35, 0.7)
            zz = math.sqrt(max(0.0, 1 - (rr / cap_r) ** 2)) * cap_r * 0.62
            self.sphere(cap_r * self.rng.uniform(0.07, 0.12), (top.x + math.cos(a) * rr, top.y + math.sin(a) * rr, top.z - cap_r * 0.08 + zz),
                        "mushroom_stem", seg=8, rings=4, scale=(1, 1, 0.45))
        return top

    def cone_roof(self, center, r, h, mat="roof_blue", rings=5, finial="gold"):
        """Toit conique à rangs d'ardoises superposés (tourelles)."""
        cx, cy, cz = center
        for i in range(rings):
            t0, t1 = i / rings, (i + 1) / rings
            rr0, rr1 = r * (1 - t0) + 0.04, r * (1 - t1) + 0.02
            self.cyl(rr0, h / rings * 1.15, (cx, cy, cz + h * t0), mat, r2=rr1, seg=14, tint=self.jitter(0.1))
        if finial:
            self.cyl(0.03, 0.35, (cx, cy, cz + h - 0.05), finial, seg=6)
            self.sphere(0.07, (cx, cy, cz + h + 0.3), finial, seg=10, rings=6)

    def column(self, loc, r, h, mat="marble", cap="marble"):
        x, y, z = loc
        self.box((r * 2.8, r * 2.8, 0.1), (x, y, z + 0.05), cap, bevel=0.02)
        self.cyl(r * 1.15, 0.08, (x, y, z + 0.1), cap, seg=14)
        self.cyl(r, h - 0.36, (x, y, z + 0.18), mat, r2=r * 0.88, seg=14)
        # Cannelures
        for i in range(8):
            a = 2 * math.pi * i / 8
            self.box((0.025, 0.025, h - 0.5), (x + math.cos(a) * r * 0.93, y + math.sin(a) * r * 0.93, z + 0.18 + (h - 0.36) / 2), mat, rot=(0, 0, math.degrees(a)), bevel=0.008, tint=0.85)
        self.cyl(r * 1.25, 0.08, (x, y, z + h - 0.18), cap, r2=r * 1.4, seg=14)
        self.box((r * 3.0, r * 3.0, 0.1), (x, y, z + h - 0.05), cap, bevel=0.02)

    def window(self, loc, rot_z, w=0.3, h=0.42, frame="wood_dark", shutters=None, arch=False, sill="stone"):
        x, y, z = loc
        rz = math.radians(rot_z)
        out = Vector((math.sin(rz), -math.cos(rz), 0))  # normale extérieure (−Y pour rot 0)
        def at(dx, dy, dz):
            p = Matrix.Rotation(rz, 4, "Z") @ Vector((dx, dy, dz))
            return (x + p.x, y + p.y, z + p.z)
        self.box((w, 0.04, h), at(0, -0.01, h / 2), "window", rot=(0, 0, rot_z), bevel=0.0)
        for sx in (-1, 1):
            self.box((0.05, 0.07, h + 0.06), at(sx * (w / 2 + 0.02), -0.03, h / 2), frame, rot=(0, 0, rot_z), bevel=0.012)
        self.box((w + 0.1, 0.07, 0.05), at(0, -0.03, h + 0.02), frame, rot=(0, 0, rot_z), bevel=0.012)
        self.box((0.03, 0.05, h), at(0, -0.04, h / 2), frame, rot=(0, 0, rot_z), bevel=0.0)
        self.box((w, 0.05, 0.03), at(0, -0.04, h * 0.55), frame, rot=(0, 0, rot_z), bevel=0.0)
        self.box((w + 0.16, 0.12, 0.05), at(0, -0.06, -0.02), sill, rot=(0, 0, rot_z), bevel=0.015)
        if arch:
            self.torus(w / 2 + 0.02, 0.035, at(0, -0.03, h), frame, rot=(90, 0, rot_z), seg=10, rseg=6, arc=180)
        if shutters:
            for sx in (-1, 1):
                self.box((w * 0.5, 0.03, h + 0.04), at(sx * (w * 0.78 + 0.04), -0.05, h / 2), shutters, rot=(0, 0, rot_z + sx * 12), bevel=0.01)
        return out

    def door(self, loc, rot_z, w=0.42, h=0.62, mat="wood_dark", frame="stone", arch=True):
        x, y, z = loc
        rz = math.radians(rot_z)
        def at(dx, dy, dz):
            p = Matrix.Rotation(rz, 4, "Z") @ Vector((dx, dy, dz))
            return (x + p.x, y + p.y, z + p.z)
        planks = 4
        for i in range(planks):
            px = -w / 2 + w / planks * (i + 0.5)
            self.box((w / planks - 0.015, 0.05, h), at(px, -0.02, h / 2), mat, rot=(0, 0, rot_z), bevel=0.01)
        for hz in (0.18, h - 0.15):
            self.box((w * 0.9, 0.03, 0.04), at(0, -0.055, hz), "iron", rot=(0, 0, rot_z), bevel=0.0)
        self.sphere(0.025, at(w * 0.3, -0.07, h * 0.45), "gold", seg=8, rings=4)
        for sx in (-1, 1):
            self.box((0.1, 0.1, h + 0.02), at(sx * (w / 2 + 0.05), -0.03, h / 2), frame, rot=(0, 0, rot_z), bevel=0.02)
        if arch:
            self.torus(w / 2 + 0.05, 0.06, at(0, -0.03, h), frame, rot=(90, 0, rot_z), seg=10, rseg=6, arc=180)
            self.poly([(-w / 2, 0, 0), (w / 2, 0, 0)] + [(math.cos(math.pi * i / 8) * w / 2, 0, math.sin(math.pi * i / 8) * w / 2) for i in range(1, 8)],
                      [[0] + list(range(8, 1, -1)) + [1]], at(0, -0.02, h), mat, rot=(0, 0, rot_z))
        else:
            self.box((w + 0.2, 0.1, 0.1), at(0, -0.03, h + 0.05), frame, rot=(0, 0, rot_z), bevel=0.02)

    def banner(self, loc, h=1.4, cloth="cloth_blue", emblem="gold", rot_z=0.0):
        x, y, z = loc
        self.cyl(0.03, h, (x, y, z), "wood_dark", seg=8)
        self.sphere(0.055, (x, y, z + h + 0.03), "gold", seg=10, rings=6)
        rz = math.radians(rot_z)
        arm = Vector((math.cos(rz), math.sin(rz), 0))
        self.cyl(0.018, 0.42, (x, y, z + h - 0.06), "wood_dark", rot=(0, 90, rot_z), seg=6)
        # Tissu ondulé à queue d'aronde
        verts, faces = [], []
        cols, rws = 4, 6
        cw, chh = 0.34, 0.62
        for j in range(rws + 1):
            for i in range(cols + 1):
                u, v = i / cols, j / rws
                wave = math.sin(u * 3.0 + v * 2.0) * 0.03
                drop = -v * chh
                if j == rws and i == cols // 2:
                    drop += 0.14
                verts.append((0.04 + u * cw, wave, drop))
        for j in range(rws):
            for i in range(cols):
                a = j * (cols + 1) + i
                faces.append((a, a + 1, a + cols + 2, a + cols + 1))
        self.poly(verts, faces, (x, y, z + h - 0.08), cloth, rot=(0, 0, rot_z), smooth=True)
        c = Vector((x, y, z + h - 0.08 - chh * 0.42)) + arm * (0.04 + cw / 2)
        self.poly([(0, 0, 0.09), (0.06, 0, 0), (0, 0, -0.09), (-0.06, 0, 0)], [(0, 1, 2, 3), (3, 2, 1, 0)], (c.x, c.y, c.z), emblem, rot=(0, 0, rot_z), scale=(1, 1, 1))
        self.poly([(0, 0, 0.09), (0.06, 0, 0), (0, 0, -0.09), (-0.06, 0, 0)], [(0, 1, 2, 3)], (c.x - math.sin(rz) * 0.04, c.y + math.cos(rz) * 0.04 - 0.08, c.z), emblem, rot=(0, 0, rot_z))

    def torch(self, loc, h=0.75, tier=None):
        x, y, z = loc
        self.cyl(0.05, h, (x, y, z), "wood_dark", r2=0.04, seg=8)
        self.cyl(0.06, 0.03, (x, y, z + h * 0.6), "iron", seg=8)
        self.cyl(0.07, 0.1, (x, y, z + h), "iron", r2=0.11, seg=10)
        with self.anim("flame%d" % len(self.pivots), (x, y, z + h + 0.12), bob=0.02, tier=tier):
            self.sphere(0.075, (x, y, z + h + 0.12), "flame", seg=8, rings=6, scale=(1, 1, 1.5))
        self.light((x, y, z + h + 0.25), "ffa040", 0.6, 2.4, tier if tier is not None else 0)

    def brazier(self, loc, r=0.16):
        x, y, z = loc
        for i in range(3):
            a = 2 * math.pi * i / 3
            self.cyl(0.02, 0.4, (x + math.cos(a) * r * 0.7, y + math.sin(a) * r * 0.7, z), "iron", rot=(math.sin(a) * 12, -math.cos(a) * 12, 0), seg=6)
        self.cyl(r * 0.6, 0.14, (x, y, z + 0.36), "bronze", r2=r, seg=14)
        with self.anim("flame%d" % len(self.pivots), (x, y, z + 0.5), bob=0.025):
            self.sphere(r * 0.6, (x, y, z + 0.52), "flame", seg=10, rings=6, scale=(1, 1, 1.6))
        self.light((x, y, z + 0.8), "ffa040", 0.8, 3.0)

    def crate(self, loc, s=0.32, rz=0.0, mat="wood_light"):
        x, y, z = loc
        self.box((s, s, s), (x, y, z + s / 2), mat, rot=(0, 0, rz), bevel=0.02)
        for dz in (0.03, s - 0.03):
            self.box((s + 0.02, s + 0.02, 0.05), (x, y, z + dz), "wood_dark", rot=(0, 0, rz), bevel=0.01)
        for k in range(4):
            a = math.radians(rz) + math.pi / 4 + k * math.pi / 2
            self.box((0.05, 0.05, s), (x + math.cos(a) * s * 0.69, y + math.sin(a) * s * 0.69, z + s / 2), "wood_dark", rot=(0, 0, rz), bevel=0.01)

    def barrel(self, loc, r=0.15, h=0.38):
        x, y, z = loc
        n = 10
        for i in range(n):
            a = 2 * math.pi * i / n
            self.box((r * 0.62, 0.035, h), (x + math.cos(a) * r * 0.97, y + math.sin(a) * r * 0.97, z + h / 2), "wood",
                     rot=(0, 0, math.degrees(a) + 90), bevel=0.008, tint=self.jitter(0.12))
        self.cyl(r * 0.95, h - 0.02, (x, y, z + 0.01), "wood_dark", seg=n)
        for hz in (0.07, h - 0.07):
            self.torus(r + 0.012, 0.014, (x, y, z + hz), "iron", seg=14, rseg=4)

    def sack(self, loc, s=0.18):
        x, y, z = loc
        self.sphere(s, (x, y, z + s * 0.8), "cloth_cream", seg=10, rings=6, scale=(1, 0.85, 0.9))
        self.cyl(s * 0.35, s * 0.4, (x, y, z + s * 1.5), "cloth_cream", r2=s * 0.2, seg=8)

    def lantern_post(self, loc, h=1.1):
        x, y, z = loc
        self.cyl(0.04, h, (x, y, z), "iron", seg=8)
        self.box((0.3, 0.04, 0.04), (x + 0.12, y, z + h - 0.02), "iron", bevel=0.0)
        self.box((0.1, 0.1, 0.16), (x + 0.24, y, z + h - 0.16), "window", bevel=0.0)
        self.cyl(0.08, 0.06, (x + 0.24, y, z + h - 0.08), "iron", r2=0.02, seg=4, rot=(0, 0, 45))
        self.light((x + 0.24, y, z + h - 0.1), "ffc060", 0.5, 2.0)

    def spoked_wheel(self, center, r, axis_rot, mat="wood", spokes=8, thick=0.06):
        self.torus(r, thick * 0.6, center, mat, rot=axis_rot, seg=20, rseg=6)
        cx, cy, cz = center
        rm = Euler([math.radians(a) for a in axis_rot]).to_matrix()
        for i in range(spokes):
            a = math.pi * i / spokes
            d = rm @ Vector((math.cos(a), math.sin(a), 0))
            ang = Euler([math.radians(a) for a in axis_rot])
            m = Matrix.LocRotScale(Vector(center), ang, Vector((1, 1, 1))) @ Matrix.Rotation(a, 4, "Z")
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            bmesh.ops.scale(bm, vec=Vector((r * 2, thick * 0.5, thick * 0.5)), verts=bm.verts)
            self.add(bm, mat, m)
        hub = rm @ Vector((0, 0, -thick * 0.6))
        self.cyl(thick * 1.2, thick * 1.2, (cx + hub.x, cy + hub.y, cz + hub.z), "iron", rot=axis_rot, seg=10)

    # --- Export -----------------------------------------------------------
    def _ao(self, bm, col):
        for f in bm.faces:
            for loop in f.loops:
                z = loop.vert.co.z
                k = 0.62 + 0.38 * min(1.0, max(0.0, z / self.ao_height))
                c = loop[col]
                loop[col] = (c[0] * k, c[1] * k, c[2] * k, 1.0)

    def export(self, path):
        scene = bpy.context.scene
        for (group, mat), (bm, col) in self.acc.items():
            pivot = self.pivots.get(group, Vector((0, 0, 0)))
            if group in self.pivots:
                bmesh.ops.translate(bm, vec=-pivot, verts=bm.verts)
            else:
                self._ao(bm, col)
            mesh = bpy.data.meshes.new("%s_%s" % (group, mat))
            bm.to_mesh(mesh)
            bm.free()
            mesh.materials.append(_material(mat))
            mesh.color_attributes.active_color = mesh.color_attributes["Col"]
            obj = bpy.data.objects.new("%s_%s" % (group, mat), mesh)
            obj.location = pivot
            scene.collection.objects.link(obj)
        for i, (pos, color, energy, rng, tier) in enumerate(self.lights):
            e = bpy.data.objects.new("light_%s_e%d_r%d_t%d_n%d" % (color, round(energy * 10), round(rng * 10), tier, i), None)
            e.location = pos
            scene.collection.objects.link(e)
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                                  export_vertex_color="ACTIVE", export_lights=False, export_cameras=False,
                                  export_extras=False, export_animations=False)
        tris = sum(len(o.data.polygons) for o in scene.objects if o.type == "MESH")
        return tris
