extends Node2D

@onready var home_return: TextureRect = $homeReturn
@onready var check_button: CheckButton = $AudioControl/CheckButtonOnOff
@onready var h_slider: HSlider = $AudioControl/HSliderVolume

const MAIN_MENU_SCENE = "res://scenes/Menu/main_menu.tscn"

func _ready() -> void:
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
