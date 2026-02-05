extends Node2D


# Called when the node enters the scene tree for the first time.
@export var initial_delay: float = 30.0 # seconds of unpaused gameplay before first meteor
@export var spawn_interval: float = 5.0 # seconds between meteors after initial delay
@export var meteor_scene: PackedScene = preload("res://scenes/meteor/meteor_scene.tscn")

var _time_unpaused: float = 0.0
var _time_since_last_spawn: float = 0.0
var _spawning_started: bool = false

func _ready() -> void:
	# Ensure we process so we can count unpaused time and spawn when due
	set_process(true)
	randomize()
	print("MeteorSpawner: ready (initial_delay=", initial_delay, ", spawn_interval=", spawn_interval, ")")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Only count gameplay time when the tree is not paused
	if get_tree().paused:
		return

	if not _spawning_started:
		_time_unpaused += delta
		if _time_unpaused >= initial_delay:
			_spawning_started = true
			_time_since_last_spawn = 0.0
			_spawn_meteor() # spawn immediately when the delay elapses
	else:
		_time_since_last_spawn += delta
		if _time_since_last_spawn >= spawn_interval:
			_time_since_last_spawn = 0.0
			_spawn_meteor()


func _spawn_meteor() -> void:
	if not meteor_scene:
		push_error("MeteorSpawner: meteor_scene not set")
		return

	var meteor = meteor_scene.instantiate()
	if meteor:
		# Add to the same parent as the spawner so global coordinates behave as expected
		get_parent().add_child(meteor)
		print("MeteorSpawner: spawned a meteor")
