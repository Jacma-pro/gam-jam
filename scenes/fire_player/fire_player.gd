extends CharacterBody2D

@export var fireball_scene = preload("res://scenes/fire_player/fire_ball/FireBall.tscn")
@export var kick_scene = preload("res://scenes/fire_player/fire_kick/FireKick.tscn")

@export_category("Mouvement")
@export var speed = 400.0
@export var jump_velocity = -660.0
@export var fall_multiplier: float = 3.0
@export var ground_deceleration: float = 1200.0 # pixels/s^2 used for move_toward

@export_category("Controles")
@export var action_left: String = "p1_left"
@export var action_right: String = "p1_right"
@export var action_jump: String = "p1_up"
@export var action_down: String = "p1_block"
@export var action_shoot: String = "p1_shoot"
@export var action_kick: String = "p1_kick"

# animation category
@export_category("Animation_fire")
@export var animation_crouch: String = "p1_crouch"
@export var animation_death: String = "p1_death"
@export var animation_hurt: String = "p1_hurt"
@export var animation_idle: String = "p1_idle"
@export var animation_jump: String = "p1_jump"
@export var animation_land: String = "p1_land"
@export var animation_kick: String = "p1_kick"
@export var animation_shoot: String = "p1_shoot"
@export var animation_walk: String = "p1_walk"

# sfx category
@onready var sfx_jump: AudioStreamPlayer2D = $"jump"
@onready var sfx_kick: AudioStreamPlayer2D = $"kick"
@onready var sfx_hurt: AudioStreamPlayer2D = $"hurt"
@onready var sfx_shoot: AudioStreamPlayer2D = $"fire_shoot"
@onready var sfx_counter: AudioStreamPlayer2D = $"counter"
@onready var sfx_block: AudioStreamPlayer2D = $"block"

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
@export var knockback_duration: float = 0.2
var is_knocked: bool = false

# Multiplicateur de dégâts reçus (peut être modifié par SceneManager)
var damage_received_multiplier: float = 1.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
# référence optionnelle au visuel de cooldown du tir
var shoot_visual: Node = null
# référence optionnelle au visuel du block
var block_visual: Node = null

# état de vie
var is_dead: bool = false


func _ready() -> void:
	animated_sprite.play(animation_idle)
	animated_sprite.stop()

	# essayer de récupérer le ShootCoolDown placé dans le même parent (Intro scene) ou à la racine
	if get_parent():
		if get_parent().has_node("ShootCoolDown2"):
			shoot_visual = get_parent().get_node("ShootCoolDown2")
		elif get_parent().has_node("ShootCoolDown"):
			shoot_visual = get_parent().get_node("ShootCoolDown")
		elif get_tree().root.has_node("ShootCoolDown2"):
			shoot_visual = get_tree().root.get_node("ShootCoolDown2")
		elif get_tree().root.has_node("ShootCoolDown"):
			shoot_visual = get_tree().root.get_node("ShootCoolDown")

	# recherche robuste du visuel du block: supporte "FireBlock" et "BlockFire" et recherche globale
	if get_parent():
		if get_parent().has_node("FireBlock"):
			block_visual = get_parent().get_node("FireBlock")
		elif get_parent().has_node("BlockFire"):
			block_visual = get_parent().get_node("BlockFire")

	# fallback: recherche globale par nom
	if not block_visual:
		block_visual = get_tree().root.find_node("FireBlock", true, false)
	if not block_visual:
		block_visual = get_tree().root.find_node("BlockFire", true, false)

	# dernier fallback: recherche par script resource basename
	if not block_visual:
		var stack: Array = []
		stack.append(get_tree().root)
		while stack.size() > 0:
			var node = stack.pop_back()
			if node is Node:
				var sc = node.get_script()
				if sc and typeof(sc) == TYPE_OBJECT:
					var path = String(sc.resource_path)
					if path.ends_with("fire_block.gd") or path.ends_with("block_fire.gd"):
						block_visual = node
				for child in node.get_children():
					stack.append(child)

	if block_visual:
		print("FirePlayer: fallback trouvé -> ", block_visual.get_path(), " script=", block_visual.get_script().resource_path)
	else:
		print("FirePlayer: AUCUN block_visual trouvé après toutes les recherches")

	if block_visual and block_visual.has_method("start_cooldown"):
		print("FirePlayer: block_visual trouvé -> ", block_visual.get_path())
	else:
		print("FirePlayer: block_visual NON trouvé ou méthode manquante. (Cherché FireBlock/BlockFire)")


func _physics_process(delta: float) -> void:
	# If dead, don't process inputs or movement
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	# Add the gravity with snappier jump behaviour.
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += gravity * delta
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
		animated_sprite.play(animation_shoot)
		shoot()
		
	# Handle Kick
	if Input.is_action_just_pressed(action_kick) and can_kick and not is_blocking and not is_knocked:
		animated_sprite.play(animation_kick)
		kick()

	# Handle jump.    
	if Input.is_action_just_pressed(action_jump) and is_on_floor() and not is_blocking and not is_knocked:
		velocity.y = jump_velocity
		sfx_jump.play()

	# Get the input direction and handle the movement/deceleration.
	var direction := 0.0
	if not is_knocked:
		direction = Input.get_axis(action_left, action_right)
	if direction:
		velocity.x = direction * speed
	else:
		# If knocked, let the player slide back using reduced friction.
		# Otherwise stop immediately to avoid unwanted walk sliding.
		if is_knocked:
			var decel_step = ground_deceleration * delta
			decel_step *= 0.25
			velocity.x = move_toward(velocity.x, 0, decel_step)
		else:
			velocity.x = 0

	_update_animation(direction)
	move_and_slide()


func _update_animation(direction):
	# If dead, force death animation and stop further changes
	if is_dead:
		if animated_sprite.animation != animation_death:
			if animated_sprite.sprite_frames.has_animation(animation_death):
				animated_sprite.sprite_frames.set_animation_loop(animation_death, false)
			animated_sprite.play(animation_death)
		return

	# If an attack animation is playing, don't interrupt it.
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
	sfx_shoot.play()

	# start visual cooldown if present
	if shoot_visual and shoot_visual.has_method("start_cooldown"):
		shoot_visual.start_cooldown(shoot_cooldown)

	# We ensure the shoot animation does not loop and play it
	if animated_sprite.sprite_frames.has_animation(animation_shoot):
		animated_sprite.sprite_frames.set_animation_loop(animation_shoot, false)

	var fireball = fireball_scene.instantiate()
	fireball.position = position + Vector2(130, -40)
	# mark shooter so the projectile won't hit its owner
	fireball.shooter = self

	# if counter active, raise spawn and amplify
	if can_counter_attack:
		sfx_counter.play()
		fireball.position += Vector2(0,0 * counter_size)
		fireball.speed *= 2.5
		if fireball.has_method("apply_counter"):
			fireball.apply_counter(2.0, counter_size)
		can_counter_attack = false

	get_parent().add_child(fireball)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func kick():
	can_kick = false
	sfx_kick.play()

	# We ensure the kick animation does not loop and play it
	if animated_sprite.sprite_frames.has_animation(animation_kick):
		animated_sprite.sprite_frames.set_animation_loop(animation_kick, false)

	var kick_instance = kick_scene.instantiate()

	kick_instance.position = Vector2(50, 10)
	add_child(kick_instance)


	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(kick_instance):
		kick_instance.queue_free()
		
	await get_tree().create_timer(kick_cooldown).timeout
	can_kick = true

func start_block_penalty():
	can_block = false
	is_blocking = false
	print("Block brisé ! Surchauffe !")
	
	# Feedback visuel : on cache le bouclier si présent
	if block_visual and block_visual.has_method("start_cooldown"):
		block_visual.start_cooldown(block_cooldown)

	await get_tree().create_timer(block_cooldown).timeout
	
	can_block = true
	current_block_time = 0.0

func take_damage(amount):
	if is_blocking:
		sfx_block.play()
		# start counter window
		can_counter_attack = true
		start_counter_window()
		print("FirePlayer a bloqué l'attaque !")
		return

	# Appliquer le multiplicateur de dégâts
	amount = amount * damage_received_multiplier

	# We ensure the hurt animation does not loop and play it
	if animated_sprite.sprite_frames.has_animation(animation_hurt):
		animated_sprite.sprite_frames.set_animation_loop(animation_hurt, false)
	animated_sprite.play(animation_hurt)
	sfx_hurt.play()
	print("Aïe ! FirePlayer a pris ", amount, " dégâts.")

	# knockback
	position += Vector2(-50, 0)

	var termo = get_tree().get_first_node_in_group("termo_bar")
	if termo:
		termo.update_temperature(-amount)
	else:
		print("Erreur : Impossible de trouver la TermoBar !")

	# Optional: if health system exists and player dies, ensure die() is called elsewhere


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
	

func die() -> void:
	# Prevent double-die
	if is_dead:
		return
	is_dead = true
	
	# disable actions
	can_shoot = false
	can_kick = false
	can_block = false
	is_blocking = false
	is_knocked = true
	
	# Si on est en l'air, on attend de toucher le sol
	while not is_on_floor():
		await get_tree().physics_frame
	
	# Une fois au sol, on coupe la physique
	set_physics_process(false)
	set_process(false)

	# MAINTENANT on peut supprimer la collision pour le "T-bag"
	# (Si on le fait avant, on passe à travers le sol)
	var collision_shape = $CollisionShape2D
	if is_instance_valid(collision_shape):
		collision_shape.queue_free()

	if animated_sprite.sprite_frames.has_animation(animation_death):
		animated_sprite.sprite_frames.set_animation_loop(animation_death, false)
		animated_sprite.play(animation_death)
		# wait for the animation to finish
		await animated_sprite.animation_finished
		
		# Stop FIRST, then force the frame to ensure it sticks
		animated_sprite.stop()
		var frames_count = animated_sprite.sprite_frames.get_frame_count(animation_death)
		if frames_count > 0:
			animated_sprite.animation = animation_death
			animated_sprite.frame = frames_count - 1
	else:
		animated_sprite.stop()
