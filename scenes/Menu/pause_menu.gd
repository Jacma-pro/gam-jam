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
	$CheckButton.button_pressed = not GameManager.is_muted
	$HSlider.value = GameManager.master_volume
	
	# Applique l'état visuel initial
	$HSlider.visible = $CheckButton.button_pressed
	_apply_audio_settings()
	
	# Donne le focus au bouton Reprendre pour qu'Espace fonctionne naturellement (ui_accept)
	$Button.grab_focus()

func _apply_audio_settings() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameManager.master_volume / 100.0))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		print("PauseMenu: Touche pause détectée via _input")
		# Pour éviter le conflit avec le SceneManager, on consomme l'événement
		get_viewport().set_input_as_handled()
		_on_resume_pressed()

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
