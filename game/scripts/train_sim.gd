extends Node
class_name TrainSim

signal train_stopped

@export var fuel := 50.0
@export var engine_power := 1.5
@export var drag := 0.5
@export var burn_rate := 2.0
@export var pressure_build := 0.5
@export var pressure_loss := 0.3
@export var debug_refuel_amount := 10.0

var speed := 0.0
var pressure := 0.0
var is_stopped := false

@onready var follower: PathFollow3D = get_parent()


func _physics_process(delta: float) -> void:
	if fuel > 0.0:
		fuel = maxf(0.0, fuel - burn_rate * delta)
		pressure = minf(1.0, pressure + pressure_build * delta)
	else:
		pressure = maxf(0.0, pressure - pressure_loss * delta)

	speed = maxf(0.0, speed + (pressure * engine_power - speed * drag) * delta)
	follower.progress += speed * delta

	var stopped := speed < 0.01 and fuel == 0.0
	if stopped and not is_stopped:
		train_stopped.emit()
	is_stopped = stopped


func add_fuel(amount: float) -> void:
	fuel += amount


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.keycode == KEY_R:
		add_fuel(debug_refuel_amount)
