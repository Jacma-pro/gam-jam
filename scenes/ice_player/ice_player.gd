extends CharacterBody2D

@export var fireball_scene = preload("res://scenes/ice_player/ice_ball/IceBall.tscn")
@export var kick_scene = preload("res://scenes/ice_player/ice_kick/IceKick.tscn")

@export_category("Mouvement")
@export var speed = 400.0
@export var jump_velocity = -600.0
@export var fall_multiplier: float = 3.0

@export_category("Controles")
@export var action_left: String = "p2_left"
@export var action_right: String = "p2_right"
@export var action_jump: String = "p2_up"
@export var action_down: String = "p2_block"
@export var action_shoot: String = "p2_shoot"
@export var action_kick: String = "p2_kick"

# animation category
@export_category("Animation_fire")
@export var animation_crouch: String = "p2_crouch"
@export var animation_death: String = "p2_death"
@export var animation_hurt: String = "p2_hurt"
@export var animation_idle: String = "p2_idle"
@export var animation_jump: String = "p2_jump"
@export var animation_land: String = "p2_land"
@export var animation_kick: String = "p2_kick"
@export var animation_shoot: String = "p2_shoot"
@export var animation_walk: String = "p2_walk"

@export var shoot_cooldown: float = 2.0
@export var kick_cooldown: float = 1.0
var can_shoot: bool = true
var can_kick: bool = true

# Block gestion
@export var max_block_time: float = 0.5
@export var block_cooldown: float = 2.0
@export var counter_attack_timer: float = 2.0
var can_counter_attack: bool = false
var counter_size = 2
var can_block: bool = true
var is_blocking: bool = false
var current_block_time: float = 0.0

# Knockback / stun
@export var knockback_strength: float = 200.0
@export var knockback_duration: float = 0.2
var is_knocked: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("default")
	# face left by default
	animated_sprite.flip_h = true
	#animated_sprite.stop()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		# Ascending
		if velocity.y < 0:
			velocity.y += gravity * delta
		# Falling
		else:
			velocity.y += gravity * fall_multiplier * delta
	
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
	if Input.is_action_just_pressed(action_shoot) and can_shoot and not is_blocking and not is_knocked:
		# ensure shoot animation does not loop and play it
		if animated_sprite.sprite_frames.has_animation(animation_shoot):
			animated_sprite.sprite_frames.set_animation_loop(animation_shoot, false)
		animated_sprite.play(animation_shoot)
		shoot()
		
	# Handle Kick
	if Input.is_action_just_pressed(action_kick) and can_kick and not is_blocking and not is_knocked:
		# ensure kick animation does not loop and play it
		if animated_sprite.sprite_frames.has_animation(animation_kick):
			animated_sprite.sprite_frames.set_animation_loop(animation_kick, false)
		animated_sprite.play(animation_kick)
		kick()

	# Handle jump.	
	if Input.is_action_just_pressed(action_jump) and is_on_floor() and not is_blocking and not is_knocked:
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var direction := 0.0
	if not is_knocked:
		direction = Input.get_axis(action_left, action_right)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction):
	# Si une animation d'attaque est en train de jouer, on ne l'interrompt pas.
	# Comme on désactive le loop dans shoot/kick, is_playing() passera à false à la fin.
	if animated_sprite.is_playing() and (animated_sprite.animation == animation_shoot or animated_sprite.animation == animation_kick or animated_sprite.animation == animation_hurt):
		return

	var target := ""
	if not is_on_floor():
		target = animation_jump
	elif is_blocking:
		target = animation_crouch
	elif direction != 0:
		target = animation_walk
	else:
		target = animation_idle

	if animated_sprite.animation != target:
		animated_sprite.play(target)


func shoot():
	can_shoot = false

	# On s'assure que l'animation ne boucle pas (pour qu'elle finisse et is_playing devienne false)
	if animated_sprite.sprite_frames.has_animation(animation_shoot):
		animated_sprite.sprite_frames.set_animation_loop(animation_shoot, false)

	var fireball = fireball_scene.instantiate()
	# spawn to the left
	fireball.position = position + Vector2(-100, 20)
	fireball.rotation = PI
	# mark shooter so the projectile won't hit its owner
	fireball.shooter = self

	# si counter actif, raise spawn and amplify
	if can_counter_attack:
		fireball.position += Vector2(0, -30 * counter_size)
		if fireball.has_method("apply_counter"):
			fireball.apply_counter(2.0, counter_size)
		can_counter_attack = false

	get_parent().add_child(fireball)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func kick():
	can_kick = false
	
	# On s'assure que l'animation ne boucle pas
	if animated_sprite.sprite_frames.has_animation(animation_kick):
		animated_sprite.sprite_frames.set_animation_loop(animation_kick, false)

	var kick_instance = kick_scene.instantiate()

	# spawn kick to the left and flip
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

	# On s'assure que l'animation ne boucle pas
	if animated_sprite.sprite_frames.has_animation(animation_hurt):
		animated_sprite.sprite_frames.set_animation_loop(animation_hurt, false)
	animated_sprite.play(animation_hurt)
	print("Aïe ! IcePlayer a pris ", amount, " dégâts.")

	position += Vector2(50, 0)

	var termo = get_tree().get_first_node_in_group("termo_bar")
	if termo:
		termo.update_temperature(amount)
	else:
		print("Erreur : Impossible de trouver la TermoBar !")

	# wait for hurt animation to finish before resuming movement animations
	if animated_sprite.animation == animation_hurt:
		await animated_sprite.animation_finished
		if animated_sprite.animation == animation_hurt:
			animated_sprite.stop()

# function for knockback, move back when hit by attack
func knockback(force: Vector2, stun_time: float = 0.0) -> void:
	# apply force once and disable inputs briefly so player slides back / stunned
	velocity += force
	is_knocked = true

	var wait_time = knockback_duration
	if stun_time > wait_time:
		wait_time = stun_time

	await get_tree().create_timer(wait_time).timeout
	is_knocked = false


func start_counter_window():
	# window during which next attack is amplified
	await get_tree().create_timer(counter_attack_timer).timeout
	can_counter_attack = false

	
	
