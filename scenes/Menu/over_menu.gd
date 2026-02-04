extends CanvasLayer

@onready var label = $VBoxContainer/Label
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

	# Focus initial
	if _focusables.size() > 0:
		_focus_index = 0
		_focusables[_focus_index].grab_focus()

func _input(_event: InputEvent) -> void:
	if nav_down and Input.is_action_just_pressed(nav_down):
		_focus_index = (_focus_index + 1) % _focusables.size()
		_focusables[_focus_index].grab_focus()
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return
	if nav_up and Input.is_action_just_pressed(nav_up):
		_focus_index = (_focus_index - 1 + _focusables.size()) % _focusables.size()
		_focusables[_focus_index].grab_focus()
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return

	if nav_ok and Input.is_action_just_pressed(nav_ok):
		var node = _focusables[_focus_index]
		if node is Button:
			# Buttons in over menu are not toggleable, emit pressed
			node.emit_signal("pressed")
			var v = get_viewport()
			if v:
				v.set_input_as_handled()
			return

	# Back here is a noop but exported for future usage
	if nav_back and Input.is_action_just_pressed(nav_back):
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return

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
