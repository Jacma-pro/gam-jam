extends Area2D

@export var damage: float = 25
@export var speed: float = 600.0 # Vitesse de chute

# Zone de spawn (Ciel)
@export var min_spawn_x: float = 50
@export var max_spawn_x: float = 1230
@export var spawn_y: float = -100.0

# Zone d'atterrissage (Sol)
@export var min_land_x: float = 50
@export var max_land_x: float = 1230
@export var land_y: float = 600.0

var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    # Connexion du signal pour détecter joueurs ou sol
    body_entered.connect(_on_body_entered)
    setup_trajectory()

func setup_trajectory() -> void:
    # 1. Choisir un point de départ aléatoire en haut
    var start_x = randf_range(min_spawn_x, max_spawn_x)
    global_position = Vector2(start_x, spawn_y)
    
    # 2. Choisir un point d'arrivée aléatoire en bas
    var target_x = randf_range(min_land_x, max_land_x)
    var target_pos = Vector2(target_x, land_y)
    
    # 3. Calculer la direction et l'angle
    direction = (target_pos - global_position).normalized()
    rotation = direction.angle() # Faire tourner le sprite vers la cible

func _process(delta: float) -> void:
    # Déplacement constant
    position += direction * speed * delta
    
    # Sécurité : Supprimer si on dépasse trop le sol
    if position.y > land_y + 100:
        queue_free()

func _on_body_entered(body: Node) -> void:
    # Si c'est un joueur
    if body.has_method("take_damage"):
        body.take_damage(damage)
        print("Météore a touché ", body.name)
        queue_free() # Disparaît après impact
    
    # Si c'est le sol (TileMap ou StaticBody)
    # On vérifie si ce n'est pas le joueur pour ne pas supprimer 2 fois
    elif body is TileMap or body is StaticBody2D: 
        # Optionnel : Faire spawner une explosion ici
        queue_free()