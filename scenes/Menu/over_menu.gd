extends CanvasLayer

@onready var label = $Label
@onready var button_replay = $VBoxContainer/Button2
@onready var button_menu = $VBoxContainer/Button3

# Navigation actions (menu navigation)
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"


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
		label.text = winner_name + " l'a remporté !"
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
