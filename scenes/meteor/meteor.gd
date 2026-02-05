extends Area2D

@export var damage: float = 25
@export var min_position: float = 50
@export var max_position: float = 1230


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#defiend a random position
	var spawn_position_x = randf_range(min_position, max_position)
	var land_position_x = randf_range(min_position, max_position)
