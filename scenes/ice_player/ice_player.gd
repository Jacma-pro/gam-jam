extends CharacterBody2D

@export var fireball_scene = preload("res://scenes/ice_player/ice_ball/IceBall.tscn")
@export var kick_scene = preload("res://scenes/ice_player/ice_kick/IceKick.tscn")

@export_category("Mouvement")
@export var speed = 500.0
@export var jump_velocity = -500.0

@export_category("Controles")
@export var action_left: String = "p2_left"
@export var action_right: String = "p2_right"
@export var action_jump: String = "p2_up"
@export var action_down: String = "p2_block"
@export var action_shoot: String = "p2_shoot"
@export var action_kick: String = "p2_kick"

@export var shoot_cooldown: float = 2.0
@export var kick_cooldown: float = 0.5
var can_shoot: bool = true
var can_kick: bool = true

# Block gestion
@export var max_block_time: float = 2.0
@export var block_cooldown: float = 2.0
@export var counter_attack_timer: float = 2.0
var can_counter_attack: bool = false
var counter_size = 2
var can_block: bool = true
var is_blocking: bool = false
var current_block_time: float = 0.0

# Knockback / stun (déclarés ici pour éviter les références non définies)
@export var knockback_strength: float = 200.0
@export var knockback_duration: float = 0.2
var is_knocked: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("default")
	#animated_sprite.stop()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle down (block)
	is_blocking = false
	if Input.is_action_pressed(action_down) and is_on_floor() and can_block:
		is_blocking = true
		current_block_time += delta
		if current_block_time >= max_block_time:
			start_block_penalty()
	elif can_block:
		current_block_time = 0.0

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

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction):
	animated_sprite.flip_h = false
	if not is_on_floor():
		animated_sprite.play("p2_jump")
	elif direction != 0:
		animated_sprite.play("p2_left")
	elif is_blocking:
		animated_sprite.play("p2_block")
	else:
		animated_sprite.play("p2_left")
		animated_sprite.stop()
		animated_sprite.frame = 0


func shoot():
	can_shoot = false
	var fireball = fireball_scene.instantiate()
	fireball.position = position + Vector2(-100, 50)
	fireball.rotation = PI

	# mark shooter so the projectile won't hit its owner
	fireball.shooter = self

	# si le joueur a une fenêtre de counter active, élever la balle et l'amplifier
	if can_counter_attack:
		# raise spawn so big counter ball doesn't hit ground
		fireball.position += Vector2(0, -30 * counter_size)
		if fireball.has_method("apply_counter"):
			fireball.apply_counter(2.0, counter_size)
		can_counter_attack = false

	get_parent().add_child(fireball)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func kick():
	can_kick = false
	var kick_instance = kick_scene.instantiate()

	kick_instance.position = Vector2(-50, 10)
	kick_instance.scale.x = -1
	add_child(kick_instance)
	
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(kick_instance):
		kick_instance.queue_free()
		
	await get_tree().create_timer(kick_cooldown).timeout
	can_kick = true

func start_block_penalty():
	can_block = false
	is_blocking = false
	await get_tree().create_timer(block_cooldown).timeout
	can_block = true
	current_block_time = 0.0

func take_damage(amount):
	if is_blocking:
		can_counter_attack = true
		start_counter_window()
		print("IcePlayer a bloqué l'attaque !")
		return
	
	print("Aïe ! IcePlayer a pris ", amount, " dégâts.")
	

	position += Vector2(50, 0)

	var termo = get_tree().get_first_node_in_group("termo_bar")
	if termo:
		termo.update_temperature(amount)
	else:
		print("Erreur : Impossible de trouver la TermoBar !")

# function for knockback, move back when hit by attack
func knockback(force: Vector2):
	velocity += force
	is_knocked = true

	await get_tree().create_timer(knockback_duration).timeout
	is_knocked = false


func start_counter_window():
	# window during which next attack is amplified
	await get_tree().create_timer(counter_attack_timer).timeout
	can_counter_attack = false

	
	
