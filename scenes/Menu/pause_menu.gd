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

# SFX optionnels (si présents dans la scène parente)
@onready var hoverSFX: AudioStreamPlayer2D = get_node_or_null("../HoverSFX")
@onready var validSFX: AudioStreamPlayer2D = get_node_or_null("../ValidSFX")


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

	# Focus initial: si audio visible, commencer par le slider pour cohérence avec les menus
	if slider_audio and slider_audio.visible:
		slider_audio.grab_focus()
	else:
		btn_resume.grab_focus()

	# Connect hover/focus SFX (si disponibles)
	var interactive_elements = [btn_resume, btn_replay, btn_menu, check_audio, slider_audio]
	for element in interactive_elements:
		if element:
			if element.has_signal("mouse_entered"):
				element.mouse_entered.connect(_play_hover_sfx)
			if element.has_signal("focus_entered"):
				element.focus_entered.connect(_play_hover_sfx)

	# Focus neighbors pour navigation manette
	if slider_audio and btn_resume:
		slider_audio.focus_neighbor_bottom = btn_resume.get_path()
		btn_resume.focus_neighbor_top = slider_audio.get_path()
	if btn_resume and btn_replay:
		btn_resume.focus_neighbor_bottom = btn_replay.get_path()
		btn_replay.focus_neighbor_top = btn_resume.get_path()
	if btn_replay and btn_menu:
		btn_replay.focus_neighbor_bottom = btn_menu.get_path()
		btn_menu.focus_neighbor_top = btn_replay.get_path()

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
				if validSFX:
					validSFX.play()
				check_audio.button_pressed = not check_audio.button_pressed

func _unhandled_input(event: InputEvent) -> void:
	# Navigation manette/clavier personnalisée si les voisins ne suffisent pas
	if event.is_action_pressed(nav_down):
		var focused = get_viewport().gui_get_focus_owner()
		if focused == slider_audio or focused == check_audio:
			btn_resume.grab_focus()
			_play_hover_sfx()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(nav_up):
		var focused2 = get_viewport().gui_get_focus_owner()
		if focused2 == btn_resume and slider_audio and slider_audio.visible:
			slider_audio.grab_focus()
			_play_hover_sfx()
			get_viewport().set_input_as_handled()

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
			# Donner le focus au slider quand on (ré)active le son
			slider_audio.grab_focus()

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))

func _play_hover_sfx() -> void:
	if hoverSFX:
		hoverSFX.play()
