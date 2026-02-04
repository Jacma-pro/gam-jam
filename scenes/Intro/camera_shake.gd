extends Camera2D

var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0
var _original_position: Vector2

func _ready() -> void:
	randomize()
	_original_position = position
	add_to_group("camera_shakers")

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var t = 0.0
		if shake_duration > 0.0:
			t = shake_time / shake_duration
		var rx = (randf() * 2.0 - 1.0) * shake_magnitude * t
		var ry = (randf() * 2.0 - 1.0) * shake_magnitude * t
		position = _original_position + Vector2(rx, ry)
	else:
		# keep the reference origin up-to-date so the camera can move normally
		_original_position = position

func shake(magnitude: float = 8.0, duration: float = 0.18) -> void:
	shake_magnitude = magnitude
	shake_duration = duration
	shake_time = duration
