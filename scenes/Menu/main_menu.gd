extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)
	$CheckButton.toggled.connect(_on_check_button_toggled)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_layout.tscn")


func _on_check_button_toggled(toggled_on: bool) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, toggled_on)
