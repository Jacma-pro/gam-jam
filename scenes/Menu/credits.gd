extends Node2D

# Navigation actions
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"

@onready var menu_music: AudioStreamPlayer2D = $MusicMenu2

@onready var home_return: Button = $Button
@onready var check_button: CheckButton = $AudioControl/CheckButtonOnOff
@onready var h_slider: HSlider = $AudioControl/HSliderVolume

@onready var hoverSFX: AudioStreamPlayer2D = $HoverSFX
@onready var validSFX: AudioStreamPlayer2D = $ValidSFX

const MAIN_MENU_SCENE = "res://scenes/Menu/main_menu.tscn"

func _ready() -> void:
	# Gestion de la musique persistante
	if get_tree().root.has_node("MusicMenu2"):
		var persistent_music = get_tree().root.get_node("MusicMenu2")
		if menu_music and menu_music != persistent_music:
			menu_music.queue_free()
		menu_music = persistent_music
		if not menu_music.playing:
			menu_music.play()
	else:
		if menu_music:
			if menu_music.get_parent() != get_tree().root:
				menu_music.get_parent().remove_child(menu_music)
				get_tree().root.add_child(menu_music)
				menu_music.owner = null
			if not menu_music.playing:
				menu_music.play()
		else:
			push_warning("Credits: MusicMenu2 node not found")

	if home_return:
		home_return.pressed.connect(_on_home_return_pressed)

	# Setup Audio Controls initial state from GameManager
	if GameManager:
		# Mirror main_menu semantics: check_button.button_pressed == sound enabled
		check_button.button_pressed = not GameManager.is_muted
		h_slider.value = GameManager.master_volume
		h_slider.step = 10
		h_slider.visible = check_button.button_pressed
		_update_audio_server()

	# Connect Audio signals
	check_button.toggled.connect(_on_check_button_toggled)
	h_slider.value_changed.connect(_on_h_slider_value_changed)

	# Default focus: audio slider if visible else check_button
	if h_slider.visible:
		h_slider.grab_focus()
	else:
		check_button.grab_focus()

	# Connect hover/focus SFX
	var interactive_elements = [home_return, check_button, h_slider]
	for element in interactive_elements:
		if element:
			element.mouse_entered.connect(_play_hover_sfx)
			element.focus_entered.connect(_play_hover_sfx)

	# Force focus neighbors
	if h_slider and home_return:
		h_slider.focus_neighbor_bottom = home_return.get_path()
		home_return.focus_neighbor_top = h_slider.get_path() if h_slider.visible else check_button.get_path()
		home_return.focus_neighbor_right = check_button.get_path()

func _on_home_return_pressed() -> void:
	if menu_music and is_instance_valid(menu_music):
		menu_music.queue_free()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(nav_back):
		_on_home_return_pressed()

# Catch inputs controls may consume
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(nav_down):
		var focused = get_viewport().gui_get_focus_owner()
		if focused == h_slider or focused == check_button:
			if home_return:
				home_return.grab_focus()
				_play_hover_sfx()
				get_viewport().set_input_as_handled()

	if event.is_action_pressed(nav_up):
		var focused2 = get_viewport().gui_get_focus_owner()
		if focused2 == home_return:
			if h_slider.visible:
				h_slider.grab_focus()
			else:
				check_button.grab_focus()
			_play_hover_sfx()
			get_viewport().set_input_as_handled()

func _on_check_button_toggled(toggled_on: bool) -> void:
	# toggled_on true = sound enabled -> is_muted = false
	GameManager.is_muted = not toggled_on
	h_slider.visible = toggled_on
	if toggled_on:
		if GameManager.master_volume == 0:
			GameManager.master_volume = 100
		h_slider.value = GameManager.master_volume
	_update_audio_server()

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value
	_update_audio_server()

func _update_audio_server() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, GameManager.is_muted)
	var vol = GameManager.master_volume
	if vol <= 0:
		AudioServer.set_bus_volume_db(master_bus, -80.0)
	else:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(vol / 100.0))

func _play_hover_sfx() -> void:
	if hoverSFX:
		hoverSFX.play()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(nav_ok):
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control:
			if focused_control == home_return:
				_on_home_return_pressed()
			elif focused_control == check_button:
				validSFX.play()
				check_button.button_pressed = not check_button.button_pressed
				GameManager.is_muted = not check_button.button_pressed
				_update_audio_server()
