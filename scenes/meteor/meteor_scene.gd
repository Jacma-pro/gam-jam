extends Area2D

@export var damage: float = 25
@export var speed: float = 500.0 # Vitesse de chute
@export var min_spin: float = -1800.0
@export var max_spin: float = 1800.0

# Zone de spawn (Ciel)
@export var min_spawn_x: float = 50
@export var max_spawn_x: float = 1230
@export var spawn_y: float = -100.0

# Zone d'atterrissage (Sol)
@export var min_land_x: float = 50
@export var max_land_x: float = 1230
@export var land_y: float = 600.0

var direction: Vector2 = Vector2.DOWN
var rotation_speed: float = 0.0

func _ready() -> void:
	# Connexion du signal pour détecter joueurs ou sol
	body_entered.connect(_on_body_entered)
	# Définir une vitesse de rotation aléatoire (en degrés par seconde exposés, convertis en radians/sec)
	var spin_deg = randf_range(min_spin, max_spin)
	rotation_speed = deg_to_rad(spin_deg)
	# Donner une rotation initiale aléatoire pour varier l'apparence
	rotation = deg_to_rad(randf_range(0.0, 360.0))
	setup_trajectory()

func setup_trajectory() -> void:
	# 1. Choisir un point de départ aléatoire en haut
	var start_x = randf_range(min_spawn_x, max_spawn_x)
	global_position = Vector2(start_x, spawn_y)
	
	# 2. Choisir un point d'arrivée aléatoire en bas
	var target_x = randf_range(min_land_x, max_land_x)
	var target_pos = Vector2(target_x, land_y)
	
	# 3. Calculer la direction
	direction = (target_pos - global_position).normalized()
	# NOTE: on ne force pas l'alignement de la rotation vers la direction pour permettre la rotation libre (tumbling)

func _process(delta: float) -> void:
	# Déplacement constant
	position += direction * speed * delta

	# Rotation continue (vitesse en radians/sec)
	rotation += rotation_speed * delta
	
	# Sécurité : Supprimer si on dépasse trop le sol
	if position.y > land_y + 100:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Si c'est un joueur
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Météore a touché ", body.name)
		queue_free() # Disparaît après impact
	
	elif body is TileMap or body is StaticBody2D: 
		# Optionnel : Faire spawner une explosion ici
		queue_free()
