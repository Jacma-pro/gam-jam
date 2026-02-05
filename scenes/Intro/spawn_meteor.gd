extends Node

# Spawner de météores : attend `initial_delay` secondes, puis spawn toutes les `spawn_interval` secondes.
@export var meteor_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var initial_delay: float = 30.0
@export var spawn_parent: NodePath = NodePath(".") # parent pour les instances (par défaut ce Node)
@export var spawn_immediately_after_initial_delay: bool = false

var _spawn_timer: Timer
var _started: bool = false

func _ready() -> void:
	if not meteor_scene:
		push_error("meteor_scene non assignée dans l'inspecteur.")
		return

	# Timer d'attente initiale
	var init_timer = Timer.new()
	init_timer.wait_time = initial_delay
	init_timer.one_shot = true
	add_child(init_timer)
	init_timer.timeout.connect(_on_initial_timeout)
	init_timer.start()

func _on_initial_timeout() -> void:
	_start_spawning()
	if spawn_immediately_after_initial_delay:
		_spawn()

func _start_spawning() -> void:
	if _started:
		return
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_timer.start()
	_started = true

func _on_spawn_timer_timeout() -> void:
	_spawn()

func _spawn() -> void:
	var meteor = meteor_scene.instantiate()
	var parent_node = get_node_or_null(spawn_parent)
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(meteor)

	# Le météore configure sa propre position dans setup_trajectory(), donc on ne la fixe pas ici.
