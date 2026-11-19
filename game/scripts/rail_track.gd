@tool
extends Path3D
class_name RailTrack

const SLEEPER_HEIGHT := 0.05
const RAIL_SIZE := Vector2(0.06, 0.08)
const SLEEPER_COLOR := Color(0.36, 0.24, 0.15)
const RAIL_COLOR := Color(0.42, 0.42, 0.46)

@export var gauge := 0.6:
	set(value):
		gauge = value
		_rebuild()
@export var sleeper_spacing := 0.4:
	set(value):
		sleeper_spacing = maxf(value, 0.05)
		_rebuild()

var _rails: MultiMeshInstance3D
var _sleepers: MultiMeshInstance3D


func _ready() -> void:
	_sleepers = MultiMeshInstance3D.new()
	_rails = MultiMeshInstance3D.new()
	add_child(_sleepers)
	add_child(_rails)
	curve_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree() or curve == null:
		return
	var count := int(curve.get_baked_length() / sleeper_spacing)

	var sleepers := _multimesh(Vector3(gauge + 0.3, SLEEPER_HEIGHT, 0.12), SLEEPER_COLOR, count)
	for i in count:
		var t := curve.sample_baked_with_rotation(i * sleeper_spacing)
		sleepers.set_instance_transform(i, t.translated_local(Vector3(0, SLEEPER_HEIGHT / 2, 0)))
	_sleepers.multimesh = sleepers

	var rails := _multimesh(Vector3(RAIL_SIZE.x, RAIL_SIZE.y, sleeper_spacing * 1.05), RAIL_COLOR, count * 2)
	for i in count:
		var t := curve.sample_baked_with_rotation((i + 0.5) * sleeper_spacing)
		for side in [-1, 1]:
			var offset := Vector3(side * gauge / 2, SLEEPER_HEIGHT + RAIL_SIZE.y / 2, 0)
			rails.set_instance_transform(i * 2 + (side + 1) / 2, t.translated_local(offset))
	_rails.multimesh = rails


func _multimesh(size: Vector3, color: Color, count: int) -> MultiMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = color
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	return mm
