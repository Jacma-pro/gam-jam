extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const PAUSE_MENU_SCENE = preload("res://scenes/Menu/pause_menu.tscn")

func _ready() -> void:
	# Met le jeu en pause pour figer les joueurs
	get_tree().paused = true
	# Connecte le signal de fin d'animation pour relancer le jeu
	animation_player.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if not get_tree().paused:
			pause_game()

func pause_game() -> void:
	var pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	get_tree().paused = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		# Reprend le jeu une fois l'intro terminée
		get_tree().paused = false
