extends PathFollow3D

# Fait avancer le train le long du chemin (Path3D parent) et le fait freiner
# en douceur pour s'arrêter devant la fin du chemin (le butoir).

@export var max_speed := 0.5 # Vitesse maximale (unités du monde par seconde)
@export var acceleration := 0.25 # Accélération au départ
@export var braking := 0.4 # Force de freinage
@export var stop_margin := 0.55 # Distance entre le centre du train et la fin du chemin à l'arrêt
@export var running := true # Décocher pour arrêter le train

var speed := 0.0


func _ready() -> void:
	loop = false


func _physics_process(delta: float) -> void:
	var track := get_parent() as Path3D
	if track == null or track.curve == null:
		return
	var stop_at := maxf(track.curve.get_baked_length() - stop_margin, 0.0)
	var remaining := stop_at - progress

	# Vitesse permise pour pouvoir encore freiner à temps : v² = 2 · freinage · distance
	var target := 0.0
	if running and remaining > 0.0:
		target = minf(max_speed, sqrt(2.0 * braking * remaining))

	if speed < target:
		speed = minf(target, speed + acceleration * delta)
	else:
		speed = maxf(target, speed - braking * delta)

	progress = minf(progress + speed * delta, stop_at)
