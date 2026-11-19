extends Node3D

@export var ground: MeshInstance3D
@export var follow_target: Node3D
@export var following := true
@export var follow_smoothing := 5.0
@export var pan_speed := 6.0
@export var edge_margin := 0.8
@export var camera_distance := 50.0
@export var zoom_min := 3.0
@export var zoom_max := 40.0
@export var zoom_step := 1.15

var bounds: AABB

@onready var camera: Camera3D = $IsometricCamera


func _ready() -> void:
	camera.position = camera.transform.basis.z * camera_distance
	camera.far = camera_distance * 4.0
	if ground:
		bounds = ground.global_transform * ground.get_aabb()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		following = not following
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = clampf(camera.size / zoom_step, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clampf(camera.size * zoom_step, zoom_min, zoom_max)


func _process(delta: float) -> void:
	if following and follow_target:
		var t := 1.0 - exp(-follow_smoothing * delta)
		global_position.x = lerpf(global_position.x, follow_target.global_position.x, t)
		global_position.z = lerpf(global_position.z, follow_target.global_position.z, t)
	else:
		var dir := _edge_direction()
		var move := Vector3(dir.x, 0.0, dir.y).normalized().rotated(Vector3.UP, rotation.y)
		global_position += move * pan_speed * delta

	if ground:
		global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
		global_position.z = clampf(global_position.z, bounds.position.z, bounds.end.z)


func _edge_direction() -> Vector2:
	var mouse := get_viewport().get_mouse_position()
	var screen := get_viewport().get_visible_rect().size
	var dir := Vector2.ZERO
	if mouse.x <= edge_margin:
		dir.x = -1.0
	elif mouse.x >= screen.x - edge_margin:
		dir.x = 1.0
	if mouse.y <= edge_margin:
		dir.y = -1.0
	elif mouse.y >= screen.y - edge_margin:
		dir.y = 1.0
	return dir
