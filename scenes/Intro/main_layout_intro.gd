extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Met le jeu en pause pour figer les joueurs
	get_tree().paused = true
	# Connecte le signal de fin d'animation pour relancer le jeu
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		# Reprend le jeu une fois l'intro terminée
		get_tree().paused = false
