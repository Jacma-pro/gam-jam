extends VBoxContainer

func _ready() -> void:
	# Connexions des boutons
	$Button.pressed.connect(_on_resume_pressed)       # Reprendre
	$Button2.pressed.connect(_on_replay_pressed)      # Rejouer
	$Button3.pressed.connect(_on_main_menu_pressed)   # Menu principal
	
	# Connexions Audio
	$CheckButton.toggled.connect(_on_check_button_toggled)
	$HSlider.value_changed.connect(_on_h_slider_value_changed)
	
	# Initialisation Audio (comme dans le menu principal)
	$CheckButton.button_pressed = true
	_on_check_button_toggled($CheckButton.button_pressed)

func _on_resume_pressed() -> void:
	# Reprendre le jeu
	get_tree().paused = false
	# Supprime la scène de menu de pause
	if owner:
		owner.queue_free()
	else:
		queue_free()

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")

# --- Logique Audio (identique au Main Menu) ---

func _on_check_button_toggled(toggled_on: bool) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, not toggled_on)
	
	$HSlider.visible = toggled_on
	if toggled_on:
		$HSlider.value = 100

func _on_h_slider_value_changed(value: float) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
