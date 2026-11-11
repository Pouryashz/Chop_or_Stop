extends Node3D


const MAIN_IDLE := "mixamo_com" # Principal
const EXTRA_IDLES := ["Idle_2/mixamo_com", "Idle_3/mixamo_com"] # Supplémentaire
const WALK := "Walk/mixamo_com" # Marche
const RUN := "Run/mixamo_com" # Course
const RUN_LIBRARY := preload("res://game/assets/Main_Girl/Cowgirl/Run/Run.fbx") # Fichier de la course
const WAIT_TIME := 10.0 # Temps d'attente
const BLEND := 0.3 # Période de transition

@export var walk_speed := 0.12 # Vitesse de marche (mètres par seconde)
@export var run_multiplier := 2.5 # La course est X fois plus rapide que la marche
@export var turn_speed := 7.0 # Vitesse de rotation du personnage
@export var max_run_time := 30.0 # Durée maximale de course avant la fatigue (secondes)
@export var recovery_time := 60.0 # Temps pour récupérer toute l'endurance (secondes)

@onready var anim: AnimationPlayer = $AnimationPlayer

var timer := 0.0
var playing_extra := false
var is_running := false # Vrai quand Shift est enfoncé pendant le déplacement
var stamina := 0.0 # Endurance restante (en secondes de course)
var exhausted := false # Vrai quand l'endurance est tombée à zéro


func _ready() -> void:
	stamina = max_run_time
	_load_run_library()
	anim.animation_finished.connect(_on_animation_finished)
	anim.play(MAIN_IDLE)


# Charge la bibliothèque "Run" par code si elle manque dans l'AnimationPlayer
func _load_run_library() -> void:
	if anim.has_animation(RUN):
		return
	if anim.has_animation_library("Run"):
		anim.remove_animation_library("Run")
	anim.add_animation_library("Run", RUN_LIBRARY)


func _process(delta: float) -> void:
	var dir := _get_move_direction()
	var wants_to_run := dir != Vector3.ZERO and Input.is_physical_key_pressed(KEY_SHIFT)

	# On court seulement si on n'est pas épuisé
	is_running = wants_to_run and not exhausted
	_update_stamina(delta)

	if dir != Vector3.ZERO:
		_move(dir, delta)
	else:
		_idle(delta)


# L'endurance baisse pendant la course et remonte le reste du temps
func _update_stamina(delta: float) -> void:
	if is_running:
		stamina -= delta
		if stamina <= 0.0:
			stamina = 0.0
			exhausted = true
			is_running = false
	else:
		stamina += (max_run_time / recovery_time) * delta
		if stamina >= max_run_time:
			stamina = max_run_time
			exhausted = false


# Lit les touches WASD et renvoie la direction au sol, relative à la caméra
func _get_move_direction() -> Vector3:
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input.y -= 1.0

	if input == Vector2.ZERO:
		return Vector3.ZERO

	var yaw := 0.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		yaw = cam.global_rotation.y

	# normalized() ramène toujours la longueur à 1 : ces valeurs ne changent pas la vitesse
	return Vector3(input.x, 0.0, input.y).normalized().rotated(Vector3.UP, yaw)


# Déplacement + rotation vers la direction + animation de marche ou de course
func _move(dir: Vector3, delta: float) -> void:
	timer = 0.0
	playing_extra = false

	var speed := walk_speed
	var move_anim := WALK
	if is_running:
		speed = walk_speed * run_multiplier
		move_anim = RUN

	global_position += dir * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), turn_speed * delta)

	if anim.current_animation != move_anim:
		anim.play(move_anim, BLEND)


# À l'arrêt : idle principal, puis un idle supplémentaire après WAIT_TIME
func _idle(delta: float) -> void:
	if playing_extra:
		return

	if anim.current_animation != MAIN_IDLE:
		anim.play(MAIN_IDLE, BLEND)

	timer += delta
	if timer >= WAIT_TIME:
		timer = 0.0
		playing_extra = true
		anim.play(EXTRA_IDLES.pick_random(), BLEND)


func _on_animation_finished(_anim_name: StringName) -> void:
	if playing_extra:
		playing_extra = false
		anim.play(MAIN_IDLE, BLEND)
