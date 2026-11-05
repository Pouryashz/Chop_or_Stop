extends Node2D
class_name TrainSim

signal train_stopped
signal wood_loaded(amount: float)
signal bandit_boarded

var position_s: float = 0.0
var speed: float = 0.0
var pressure: float = 0.0
var fuel: float = 50.0
var is_stopped: bool = false

@export var engine_power: float = 10.0
@export var drag: float = 0.5
@export var burn_rate: float = 2.0
@export var pressure_build: float = 0.5
@export var pressure_loss: float = 0.3

func _physics_process(delta: float) -> void:
	if fuel > 0.0:
		fuel = maxf(0.0, fuel - burn_rate * delta)
		pressure = clampf(pressure + pressure_build * delta, 0.0, 1.0)
	else:
		pressure = clampf(pressure - pressure_loss * delta, 0.0, 1.0)

	var engine_force: float = pressure * engine_power
	var acceleration: float = engine_force - (speed * drag)
	
	speed = maxf(0.0, speed + acceleration * delta)
	position_s += speed * delta
	
	get_parent().progress = position_s
	
	if speed < 0.01 and fuel == 0.0:
		speed = 0.0
		if not is_stopped:
			is_stopped = true
			train_stopped.emit()
	elif speed > 0.01:
		is_stopped = false

func add_fuel(amount: float) -> void:
	fuel += amount
	wood_loaded.emit(amount)
