extends Area2D

@export var damage: float = 15.0
@export var knockback_base: float = 200.0
@export var shove_margin: float = 4.0

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
			# Collision-safe movement: prefer move_and_collide for CharacterBody2D-like bodies
			var margin: float = 4.0
			if body.has_method("move_and_collide"):
				var _collision = body.move_and_collide(shove)
			else:
				var from = body.global_position
				var to = from + shove
				var space_state = get_world_2d().direct_space_state
				var exclude = [get_parent(), self, body]
				var params = PhysicsRayQueryParameters2D.new()
				params.from = from
				params.to = to
				params.exclude = exclude
				var res = space_state.intersect_ray(params)
				if res:
					var pos = res.position - res.normal * margin
					body.global_position = pos
				else:
					body.global_position = to
			if body.has_method("knockback"):
				body.knockback(Vector2(0, 0), 0.2)


func apply_counter(multiplier: float, size_mult: float) -> void:
	# amplify damage and visual size when player used counter-attack
	damage *= multiplier
	scale *= size_mult
