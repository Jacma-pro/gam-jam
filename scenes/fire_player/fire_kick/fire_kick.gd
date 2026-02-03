extends Area2D

@export var damage: float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body):
	if body == get_parent():
		return
	print("touche cac : ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("IcePlayer touché par un coup de pied !")


func apply_counter(multiplier: float, size_mult: float) -> void:
	# amplify damage and visual size when player used counter-attack
	damage *= multiplier
	scale *= size_mult
