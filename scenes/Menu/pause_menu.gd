extends VBoxContainer

# Navigation actions (menu navigation)
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"


func _ready() -> void:
	# Connexions des boutons
	$Button.pressed.connect(_on_resume_pressed)       # Reprendre
	$Button2.pressed.connect(_on_replay_pressed)      # Rejouer
	$Button3.pressed.connect(_on_main_menu_pressed)   # Menu principal
	
	# Connexions Audio
	$CheckButton.toggled.connect(_on_check_button_toggled)
	$HSlider.value_changed.connect(_on_h_slider_value_changed)
	
	# Initialisation Audio (comme dans le menu principal)
	$CheckButton.pressed = not GameManager.is_muted
	$HSlider.value = GameManager.master_volume
	
	# Applique l'état visuel initial
	$HSlider.visible = $CheckButton.pressed
	_apply_audio_settings()
	
	# Donne le focus au bouton Reprendre pour qu'Espace fonctionne naturellement (ui_accept)
	$Button.grab_focus()
	# focusables initial
	if _focusables.size() > 0:
		_focus_index = 0
		_focusables[_focus_index].grab_focus()

func _apply_audio_settings() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameManager.master_volume / 100.0))

func _input(_event: InputEvent) -> void:
	# Pause toggle (keep space/escape behavior): allow re-pressing to unpause
	if Input.is_action_just_pressed("pause"):
		print("PauseMenu: Touche pause détectée via _input")
		get_viewport().set_input_as_handled()
		_on_resume_pressed()
		return

	# Navigation via controller/keyboard (use Input singleton to avoid event type issues)
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

	# Left / Right for slider (allow holding)
	if nav_left and Input.is_action_just_pressed(nav_left):
		var node = _focusables[_focus_index]
		if node is HSlider:
			node.value = max(node.min_value, node.value - 2)
			var v = get_viewport()
			if v:
				v.set_input_as_handled()
			return
	if nav_right and Input.is_action_just_pressed(nav_right):
		var node = _focusables[_focus_index]
		if node is HSlider:
			node.value = min(node.max_value, node.value + 2)
			var v = get_viewport()
			if v:
				v.set_input_as_handled()
			return

	# OK to activate focused control
	if nav_ok and Input.is_action_just_pressed(nav_ok):
		var node = _focusables[_focus_index]
		if node is CheckButton:
			var new_state = false
			if "button_pressed" in node:
				new_state = not node.button_pressed
				node.button_pressed = new_state
			elif "pressed" in node:
				new_state = not node.pressed
				node.pressed = new_state
			else:
				if node.has_method("is_pressed") and node.has_method("set_pressed"):
					new_state = not node.is_pressed()
					node.set_pressed(new_state)
			node.emit_signal("toggled", new_state)
		elif node is Button:
			node.emit_signal("pressed")
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return

	# Back resumes the game
	if nav_back and Input.is_action_just_pressed(nav_back):
		_on_resume_pressed()
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return

func _on_resume_pressed() -> void:
	# Reprendre le jeu
	get_tree().paused = false
	# Supprime la scène de menu de pause (le parent CanvasLayer)
	# Le script est attaché au VBoxContainer, donc son parent est la racine du menu
	get_parent().queue_free()

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")

# --- Logique Audio (identique au Main Menu) ---

func _on_check_button_toggled(toggled_on: bool) -> void:
	# toggled_on = true (Son Activé) -> is_muted = false
	GameManager.is_muted = not toggled_on
	
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	
	$HSlider.visible = toggled_on
	
	if toggled_on:
		if GameManager.master_volume == 0:
			GameManager.master_volume = 100
		$HSlider.value = GameManager.master_volume

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
