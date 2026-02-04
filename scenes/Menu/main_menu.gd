extends VBoxContainer

# Navigation actions (menu navigation - default names assumed)
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)
	$CheckButton.toggled.connect(_on_check_button_toggled)
	$HSlider.value_changed.connect(_on_h_slider_value_changed)
	
	# Initialisation depuis le GameManager
	# CheckButton ON = Son activé (donc is_muted = false)
	$CheckButton.pressed = not GameManager.is_muted
	$HSlider.value = GameManager.master_volume
	
	# Applique l'état visuel initial
	$HSlider.visible = $CheckButton.pressed
	
	# Applique l'état audio initial
	_apply_audio_settings()

	# Focus initial
	if _focusables.size() > 0:
		_focus_index = 0
		_focusables[_focus_index].grab_focus()


func _input(_event: InputEvent) -> void:
	# Use Input singleton checks to avoid calling is_action on unrelated event types
	# Navigate down
	if nav_down and Input.is_action_just_pressed(nav_down):
		if _focusables.size() > 0:
			_focus_index = (_focus_index + 1) % _focusables.size()
			_focusables[_focus_index].grab_focus()
			get_viewport().set_input_as_handled()
			return
	# Navigate up
	if nav_up and Input.is_action_just_pressed(nav_up):
		if _focusables.size() > 0:
			_focus_index = (_focus_index - 1) % _focusables.size()
			_focusables[_focus_index].grab_focus()
			get_viewport().set_input_as_handled()
			return

	# Left / Right for the slider when focused (allow holding)
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

	# OK = activate focused button / toggle
	if nav_ok and Input.is_action_just_pressed(nav_ok):
		var node = _focusables[_focus_index]
		if node is CheckButton:
			# Some CheckButton variants use 'button_pressed' (used elsewhere in code), prefer it
			var new_state = false
			if "button_pressed" in node:
				new_state = not node.button_pressed
				node.button_pressed = new_state
			elif "pressed" in node:
				new_state = not node.pressed
				node.pressed = new_state
			else:
				# fallback: try methods
				if node.has_method("is_pressed") and node.has_method("set_pressed"):
					new_state = not node.is_pressed()
					node.set_pressed(new_state)
			# emit toggled to notify listeners
			node.emit_signal("toggled", new_state)
		elif node is Button:
			# Regular button: emit pressed
			node.emit_signal("pressed")
		var v = get_viewport()
		if v:
			v.set_input_as_handled()
		return

	# Back is reserved for future use in this menu (no-op here)
	if nav_back and Input.is_action_just_pressed(nav_back):
		var v = get_viewport()
		if v:
			v.set_input_as_handled()

func _apply_audio_settings() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameManager.master_volume / 100.0))

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Intro/main_layout_intro.tscn")

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
