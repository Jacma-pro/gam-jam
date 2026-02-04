extends Area2D

@export var damage: float = 20.0
@export var knockback_base: float = 200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_body_entered(body):
	if body == get_parent():
		return
	print("touche cac : ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("FirePlayer touché par un coup de pied !")

		# apply an instant positional shove away from the kicker (no sliding)
		if is_instance_valid(get_parent()):
			var hdir = 1 if body.global_position.x > get_parent().global_position.x else -1
			var shove = Vector2(hdir * knockback_base * 1.5, 0)
			body.global_position += shove
			if body.has_method("knockback"):
				body.knockback(Vector2(0, 0), 0.2)


func apply_counter(multiplier: float, size_mult: float) -> void:
	# amplify damage and visual size when player used counter-attack
	damage *= multiplier
	scale *= size_mult
