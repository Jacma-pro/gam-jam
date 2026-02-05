extends Node2D

@onready var home_return: TextureRect = $homeReturn

const MAIN_MENU_SCENE = "res://scenes/Menu/main_menu.tscn"

func _ready() -> void:
	if home_return:
		home_return.gui_input.connect(_on_home_return_gui_input)

func _on_home_return_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
