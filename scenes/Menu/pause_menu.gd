extends VBoxContainer

# Navigation actions (menu navigation)
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"

# Références aux nœuds
@onready var btn_resume = $Button
@onready var btn_replay = $Button2
@onready var btn_menu = $Button3

# Les contrôles Audio sont maintenant dans un autre VBoxContainer (VBoxContainer2)
@onready var check_audio = $"../VBoxContainer2/CheckButton"
@onready var slider_audio = $"../VBoxContainer2/HSlider"


func _ready() -> void:
	# Connexions des boutons
	btn_resume.pressed.connect(_on_resume_pressed)       # Reprendre
	btn_replay.pressed.connect(_on_replay_pressed)      # Rejouer
	btn_menu.pressed.connect(_on_main_menu_pressed)   # Menu principal
	
	# Connexions Audio
	if check_audio:
		check_audio.toggled.connect(_on_check_button_toggled)
		# Initialisation Audio
		check_audio.button_pressed = not GameManager.is_muted
	
	if slider_audio:
		slider_audio.value_changed.connect(_on_h_slider_value_changed)
		slider_audio.step = 10
		slider_audio.value = GameManager.master_volume
		# Applique l'état visuel initial
		slider_audio.visible = check_audio.button_pressed

	# Applique l'état audio initial
	_apply_audio_settings()
	
	# Donne le focus au bouton Reprendre pour qu'Espace fonctionne naturellement (ui_accept)
	btn_resume.grab_focus()

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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(nav_ok):
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control:
			if focused_control == btn_resume:
				_on_resume_pressed()
			if focused_control == btn_replay:
				_on_replay_pressed()
			if focused_control == btn_menu:
				_on_main_menu_pressed()
			elif focused_control == check_audio:
				check_audio.button_pressed = not check_audio.button_pressed

# --- Logique Audio (identique au Main Menu) ---

func _on_check_button_toggled(toggled_on: bool) -> void:
	# toggled_on = true (Son Activé) -> is_muted = false
	GameManager.is_muted = not toggled_on
	
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	
	if slider_audio:
		slider_audio.visible = toggled_on
		if toggled_on:
			if GameManager.master_volume == 0:
				GameManager.master_volume = 100
			slider_audio.value = GameManager.master_volume

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
