extends AnimatedSprite2D


# Cache le sprite pendant la durée du cooldown puis le réaffiche
func start_cooldown(duration: float) -> void:
	visible = false
	await get_tree().create_timer(duration).timeout
	visible = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
