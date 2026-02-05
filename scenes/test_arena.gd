# (ou le nom de votre script principal)

extends Node2D 

@export var meteor_scene: PackedScene = preload("res://scenes/meteor/meteor_scene.tscn")
@export var meteor_interval_min: float = 1.0
@export var meteor_interval_max: float = 3.0

var spawn_timer: Timer

func _ready() -> void:
	# Création d'un timer pour gérer les vagues
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_meteor_routine)
	
	# Lancer le cycle
	_start_next_spawn()

func _start_next_spawn() -> void:
	# Temps aléatoire avant la prochaine météore
	spawn_timer.wait_time = randf_range(meteor_interval_min, meteor_interval_max)
	spawn_timer.start()

func _spawn_meteor_routine() -> void:
	spawn_meteor()
	_start_next_spawn() # Relance le timer pour la suivante

func spawn_meteor() -> void:
	if meteor_scene:
		var meteor = meteor_scene.instantiate()
		add_child(meteor)
		# Le météore gère sa position tout seul dans son _ready()
