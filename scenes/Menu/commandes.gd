extends Node2D

@onready var menu_music: AudioStreamPlayer2D = $MusicMenu2

@onready var home_return: TextureRect = $homeReturn
@onready var check_button: CheckButton = $AudioControl/CheckButtonOnOff
@onready var h_slider: HSlider = $AudioControl/HSliderVolume

const MAIN_MENU_SCENE = "res://scenes/Menu/main_menu.tscn"

func _ready() -> void:
	if get_tree().root.has_node("MusicMenu2"):
		# Une musique joue déjà, on l'utilise
		var persistent_music = get_tree().root.get_node("MusicMenu2")
		
		# Si on a une musique locale (du tscn), on la supprime pour ne pas avoir de doublon
		if menu_music and menu_music != persistent_music:
			menu_music.queue_free()
		
		# On met à jour la référence et on relance si besoin
		menu_music = persistent_music
		if not menu_music.playing:
			menu_music.play()
	else:
		# Pas de musique en cours, on promeut la nôtre
		if menu_music:
			if menu_music.get_parent() != get_tree().root:
				menu_music.get_parent().remove_child(menu_music)
				get_tree().root.add_child(menu_music)
				menu_music.owner = null
			
			if not menu_music.playing:
				menu_music.play()
		else:
			push_warning("Commandes: MusicMenu2 node not found")
	# Setup Home Return handling
	if home_return:
		home_return.gui_input.connect(_on_home_return_gui_input)
	
	# Setup Audio Controls initial state from GameManager
	if GameManager:
		check_button.button_pressed = GameManager.is_muted
		h_slider.value = GameManager.master_volume
		_update_audio_server() # Ensure actual audio matches GameManager state
	
	# Connect Audio signals
	check_button.toggled.connect(_on_check_button_toggled)
	h_slider.value_changed.connect(_on_h_slider_value_changed)

func _on_home_return_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# On supprime la musique persistante pour laisser place à celle du Menu Principal
		if menu_music:
			menu_music.queue_free()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_check_button_toggled(toggled_on: bool) -> void:
	if GameManager:
		GameManager.is_muted = toggled_on
	_update_audio_server()

func _on_h_slider_value_changed(value: float) -> void:
	if GameManager:
		GameManager.master_volume = value
	_update_audio_server()

func _update_audio_server() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	
	if GameManager:
		AudioServer.set_bus_mute(master_bus, GameManager.is_muted)
		# Assuming slider is 0-100, convert to linear 0-1 then db
		# However, if 0, linear_to_db is -inf.
		var vol = GameManager.master_volume
		if vol <= 0:
			AudioServer.set_bus_volume_db(master_bus, -80.0) # Mute effectively
		else:
			AudioServer.set_bus_volume_db(master_bus, linear_to_db(vol / 100.0))
