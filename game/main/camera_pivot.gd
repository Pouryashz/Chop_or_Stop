extends Node3D

@export var ground: MeshInstance3D      # Assigner ici le nœud Ground
@export var pan_speed := 0.9           # Vitesse de déplacement de la caméra (mètres par seconde)
@export var edge_margin := 0.8         # Distance au bord de l'écran qui déclenche le déplacement (pixels)
@export var border := 0.0               # Marge à garder par rapport au bord du terrain (mètres)

var min_x := -INF
var max_x := INF
var min_z := -INF
var max_z := INF


func _ready() -> void:
	if ground == null:
		push_warning("Aucun Ground assigné au CameraPivot : la caméra n'a pas de limites.")
		return
	# Calcul des limites à partir de la taille réelle du terrain
	var box: AABB = ground.global_transform * ground.get_aabb()
	min_x = box.position.x + border
	max_x = box.end.x - border
	min_z = box.position.z + border
	max_z = box.end.z - border


func _process(delta: float) -> void:
	var viewport := get_viewport()
	var mouse := viewport.get_mouse_position()
	var screen := viewport.get_visible_rect().size

	# Détection de la souris près des bords de l'écran
	var dir := Vector2.ZERO
	if mouse.x <= edge_margin:
		dir.x -= 1.0
	elif mouse.x >= screen.x - edge_margin:
		dir.x += 1.0
	if mouse.y <= edge_margin:
		dir.y -= 1.0
	elif mouse.y >= screen.y - edge_margin:
		dir.y += 1.0

	if dir == Vector2.ZERO:
		return

	# Direction du déplacement au sol, en tenant compte de la rotation Y de la caméra
	var move := Vector3(dir.x, 0.0, dir.y).normalized().rotated(Vector3.UP, rotation.y)
	global_position += move * pan_speed * delta

	# La caméra ne sort pas des limites du terrain
	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.z = clampf(global_position.z, min_z, max_z)
