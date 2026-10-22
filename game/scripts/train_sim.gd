extends Node2D
class_name TrainSim

signal train_stopped
signal wood_loaded(amount: float)
signal bandit_boarded

var position_s: float = 0.0
var speed: float = 0.0
var pressure: float = 0.0
var fuel: float = 50.0

@export var drag: float = 0.5
@export var burn_rate: float = 2.0
@export var pressure_build: float = 5.0
@export var pressure_loss: float = 3.0

func _process(delta: float) -> void:
	if fuel > 0.0:
		fuel = max(0.0, fuel - burn_rate * delta)
		pressure += pressure_build * delta
	else:
		pressure = max(0.0, pressure - pressure_loss * delta)

	var engine_force: float = pressure * 2.0
	
	var acceleration: float = engine_force - (speed * drag)
	speed = max(0.0, speed + acceleration * delta)
	
	position_s += speed * delta
	
	position.x = position_s
	
	if speed == 0.0 and fuel == 0.0:
		emit_signal("train_stopped")

func add_fuel(amount: float) -> void:
	fuel += amount
	emit_signal("wood_loaded", amount)
