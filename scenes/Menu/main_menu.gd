extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)
	$CheckButton.toggled.connect(_on_check_button_toggled)
	$HSlider.value_changed.connect(_on_h_slider_value_changed)
	
	# Initialisation : Son activé par défaut
	$CheckButton.button_pressed = true
	# Applique l'état initial
	_on_check_button_toggled($CheckButton.button_pressed)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Intro/main_layout_intro.tscn")


func _on_check_button_toggled(toggled_on: bool) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	
	# CheckButton ON (toggled_on = true) -> Son Activé (Mute = false)
	# CheckButton OFF (toggled_on = false) -> Son Coupé (Mute = true)
	AudioServer.set_bus_mute(master_bus_index, not toggled_on)
	
	$HSlider.visible = toggled_on
	
	if toggled_on:
		$HSlider.value = 100


func _on_h_slider_value_changed(value: float) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
