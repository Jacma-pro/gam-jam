extends Camera2D

var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0

func _ready() -> void:
	randomize()
	add_to_group("camera_shakers")

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var t = 0.0
		if shake_duration > 0.0:
			t = shake_time / shake_duration
		var rx = (randf() * 2.0 - 1.0) * shake_magnitude * t
		var ry = (randf() * 2.0 - 1.0) * shake_magnitude * t
		offset = Vector2(rx, ry)
	else:
		offset = Vector2.ZERO

func shake(magnitude: float = 8.0, duration: float = 0.18) -> void:
	shake_magnitude = magnitude
	shake_duration = duration
	shake_time = duration
