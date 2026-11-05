extends Node3D
@export var train_sim: Node2D

func _process(_delta: float) -> void:
	if train_sim:
	
		position.x = train_sim.global_position.x
		position.y = -train_sim.global_position.y
		
		rotation.z = -train_sim.rotation
