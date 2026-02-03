extends CharacterBody2D

@export var fireball_scene = preload("res://scenes/fire_player/fire_ball/FireBall.tscn")
@export var kick_scene = preload("res://scenes/fire_player/fire_kick/FireKick.tscn")

@export_category("Mouvement")
@export var speed = 500.0
@export var jump_velocity = -500.0

@export_category("Controles")
@export var action_left: String = "p1_left"
@export var action_right: String = "p1_right"
@export var action_jump: String = "p1_up"
@export var action_down: String = "p1_block"
@export var action_shoot: String = "p1_shoot"
@export var action_kick: String = "p1_kick"

@export var shoot_cooldown: float = 2.0
@export var kick_cooldown: float = 0.5
var can_shoot: bool = true
var can_kick: bool = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("default")
	animated_sprite.stop()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle down (block)
	var is_blocking = false
	if Input.is_action_pressed(action_down) and is_on_floor():
		is_blocking = true

	# Handle shooting.
	if Input.is_action_just_pressed(action_shoot) and can_shoot and not is_blocking:
		shoot()
		
	# Handle Kick
	if Input.is_action_just_pressed(action_kick) and can_kick and not is_blocking:
		kick()

	# Handle jump.	
	if Input.is_action_just_pressed(action_jump) and is_on_floor() and not is_blocking:
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis(action_left, action_right)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	_update_animation(direction)
	move_and_slide()


func _update_animation(direction):
	if not is_on_floor():
		animated_sprite.play("p1_jump")
	elif direction != 0:
		animated_sprite.play("p1_right")
	elif Input.is_action_pressed(action_down):
		animated_sprite.play("p1_block")
	else:
		animated_sprite.play("p1_right")
		animated_sprite.stop()
		animated_sprite.frame = 0


func shoot():
	can_shoot = false
	var fireball = fireball_scene.instantiate()
	fireball.position = position + Vector2(100, 0)
	
	get_parent().add_child(fireball)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func kick():
	can_kick = false
	var kick_instance = kick_scene.instantiate()

	kick_instance.position = Vector2(50, 10)
	add_child(kick_instance)
	
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(kick_instance):
		kick_instance.queue_free()
		
	await get_tree().create_timer(kick_cooldown).timeout
	can_kick = true

func take_damage(amount):
	print("Aïe ! FirePlayer a pris ", amount, " dégâts.")
