extends CanvasLayer

@onready var label = $VBoxContainer/Label
@onready var button_replay = $VBoxContainer/Button2
@onready var button_menu = $VBoxContainer/Button3
@onready var color_rect = $ColorRect

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
		button_replay.grab_focus() # Donne le focus au premier bouton
	else:
		print("OverMenu: ERREUR - Button2 (Replay) introuvable")

	if button_menu:
		button_menu.pressed.connect(_on_main_menu_pressed)
	else:
		print("OverMenu: ERREUR - Button3 (Menu) introuvable")

	# Configure les voisins de focus pour la navigation manette/clavier
	if button_replay and button_menu:
		button_replay.focus_neighbor_bottom = button_menu.get_path()
		button_menu.focus_neighbor_top = button_replay.get_path()

func set_winner(winner_name: String) -> void:
	print("OverMenu: set_winner appelé avec ", winner_name)
	if label:
		label.text = winner_name + " WINS!"
		
		if winner_name == "PYRO TEAM":
			# Pyro gagne : Fond Rouge transparent, Texte Bleu
			if color_rect:
				color_rect.color = Color(0.85, 0.22, 0.22, 0.36)
			label.add_theme_color_override("font_color", Color(0.85, 0.0, 0.0, 1.0))
		else:
			# Cryo gagne : Fond Bleu transparent, Texte Rouge
			if color_rect:
				color_rect.color = Color(0.22, 0.27, 0.85, 0.36)
			label.add_theme_color_override("font_color", Color(0.116, 0.142, 0.89, 1.0))
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


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(nav_ok):
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control:
			if focused_control == button_replay:
				_on_replay_pressed()
			if focused_control == button_menu:
				_on_main_menu_pressed()


func _unhandled_input(event: InputEvent) -> void:
	# Navigation manette/clavier personnalisée si les voisins ne suffisent pas
	if event.is_action_pressed(nav_down):
		var focused = get_viewport().gui_get_focus_owner()
		if focused == button_replay:
			button_menu.grab_focus()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(nav_up):
		var focused2 = get_viewport().gui_get_focus_owner()
		if focused2 == button_menu:
			button_replay.grab_focus()
			get_viewport().set_input_as_handled()
