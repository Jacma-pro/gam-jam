extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
const NEXT_SCENE = "res://scenes/Intro/main_layout_intro.tscn"

func _ready() -> void:
	if video_player:
		video_player.finished.connect(_on_video_finished)
	else:
		# Fallback si pas de video player, on passe direct
		call_deferred("_on_video_finished")

func _on_video_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)

func _input(event: InputEvent) -> void:
	# Optionnel : permettre de passer la cinématique avec une touche (Espace ou Entrée ou Echappe)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_video_finished()
