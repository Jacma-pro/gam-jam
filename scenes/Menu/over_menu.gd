extends CanvasLayer

@onready var label = $VBoxContainer/Label
@onready var button_replay = $VBoxContainer/Button2
@onready var button_menu = $VBoxContainer/Button3

func _ready() -> void:
	print("OverMenu: _ready appelé")
	# Connexions des boutons
	if button_replay:
		button_replay.pressed.connect(_on_replay_pressed)
	else:
		print("OverMenu: ERREUR - Button2 (Replay) introuvable")

	if button_menu:
		button_menu.pressed.connect(_on_main_menu_pressed)
	else:
		print("OverMenu: ERREUR - Button3 (Menu) introuvable")

func set_winner(winner_name: String) -> void:
	print("OverMenu: set_winner appelé avec ", winner_name)
	if label:
		label.text = "La faction " + winner_name + " l'a remporté !"
	else:
		print("OverMenu: ERREUR - Label introuvable")

func _on_replay_pressed() -> void:
	get_tree().paused = false
	queue_free() # Détruit le menu
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	queue_free() # Détruit le menu
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
