class_name PlacementGhost
extends Node3D
## Aperçu translucide d'un bâtiment en cours de placement, avec emprise
## colorée (vert = emplacement libre, rouge = occupé).

const VALID := Color(0.35, 1.0, 0.45, 0.45)
const INVALID := Color(1.0, 0.3, 0.3, 0.5)

var data: BuildingData
var cell := Vector2i.ZERO
var valid := false
var _footprint_mat: StandardMaterial3D


func setup(p_data: BuildingData, level: int) -> void:
	data = p_data
	var model := BuildingModels.build(data, level)
	add_child(model)
	_make_transparent(model)
	_footprint_mat = StandardMaterial3D.new()
	_footprint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_footprint_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var plane := PlaneMesh.new()
	plane.size = Vector2(data.footprint)
	var fp := MeshKit.part(self, plane, _footprint_mat, Vector3(0, 0.03, 0))
	fp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Flèches de déplacement
	var arrow_mat := MeshKit.glow_mat(Color("ffe17a"), 1.2)
	for i in 4:
		var a := i * PI / 2.0
		var dir := Vector3(cos(a), 0, sin(a))
		var off := (data.footprint.x / 2.0 + 0.45)
		MeshKit.part(self, MeshKit.cylinder(0.24, 0.05, -1, 3), arrow_mat, dir * off + Vector3(0, 0.05, 0), Vector3(0, -rad_to_deg(a), 0))


func set_cell(p_cell: Vector2i, is_valid: bool) -> void:
	cell = p_cell
	valid = is_valid
	position = Vector3(cell.x + data.footprint.x / 2.0, 0.05, cell.y + data.footprint.y / 2.0)
	_footprint_mat.albedo_color = VALID if valid else INVALID


func _make_transparent(n: Node) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			c.transparency = 0.3
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if c is Light3D:
			c.visible = false
		_make_transparent(c)
