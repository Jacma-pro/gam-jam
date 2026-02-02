extends CharacterBody2D

@export_category("Mouvement")
@export var speed = 400.0
@export var jump_velocity = -600.0

@export_category("Controles")
@export var action_left = "p1_left"
@export var action_right = "p1_right"
@export var action_jump = "p1_up"

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed(action_jump) and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis(action_left, action_right)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
