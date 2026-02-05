extends VBoxContainer

# Navigation actions (menu navigation - default names assumed)
@export_category("Navigation")
@export var nav_up: String = "up_nav_menu"
@export var nav_down: String = "down_nav_menu"
@export var nav_left: String = "left_nav_menu"
@export var nav_right: String = "right_nav_menu"
@export var nav_ok: String = "ok_nav_menu"
@export var nav_back: String = "back_nav_menu"

# Menu music: we search robustly because the AudioStreamPlayer2D may be reparented to the root
@onready var menu_music: AudioStreamPlayer2D = null

# Références aux nœuds (adaptées à la nouvelle structure)
@onready var button_jouer: Button = $ButtonJouer
@onready var button_commandes: Button = $ButtonCommandes
@onready var button_credits: Button = $ButtonCredits

# Les contrôles audio sont dans un autre conteneur (frère de celui-ci)
@onready var check_button: CheckButton = $"../AudioControl/CheckButtonOnOff"
@onready var h_slider: HSlider = $"../AudioControl/HSliderVolume"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find or pick the MenuMusic node. Prefer an existing one in the scene tree root
	if not menu_music:
		var found = _find_node_by_name_in_tree("MenuMusic")
		if found and found is AudioStreamPlayer2D:
			menu_music = found
		else:
			var sibling = $"../MenuMusic" if has_node("../MenuMusic") else null
			if sibling and sibling is AudioStreamPlayer2D:
				menu_music = sibling

	# If we found a MenuMusic and it isn't a child of the root, reparent it so it persists
	if menu_music:
		if menu_music.get_parent() != get_tree().root:
			menu_music.get_parent().remove_child(menu_music)
			get_tree().root.add_child(menu_music)
			# Remove owner so the node isn't saved with the scene
			menu_music.owner = null

		# Start playing if not already
		if not menu_music.playing:
			menu_music.play()
	else:
		push_warning("MainMenu: MenuMusic node not found")

	# Connexion des boutons
	button_jouer.pressed.connect(_on_button_jouer_pressed)
	button_commandes.pressed.connect(_on_button_commandes_pressed)
	button_credits.pressed.connect(_on_button_credits_pressed)

	# Connexion des contrôles audio
	check_button.toggled.connect(_on_check_button_toggled)
	h_slider.value_changed.connect(_on_h_slider_value_changed)

	# Initialisation depuis le GameManager
	# CheckButton ON = Son activé (donc is_muted = false)
	check_button.button_pressed = not GameManager.is_muted
	h_slider.step = 10
	h_slider.value = GameManager.master_volume

	# Applique l'état visuel initial
	h_slider.visible = check_button.button_pressed

	# Applique l'état audio initial
	_apply_audio_settings()

	# Focus initial sur le bouton Jouer
	button_jouer.grab_focus()


func _find_node_by_name_in_tree(target_name: String) -> Node:
	# Iterative DFS to avoid calling missing methods on unexpected root types
	var stack: Array = []
	stack.append(get_tree().root)

	while stack.size() > 0:
		var node = stack.pop_back()
		# get_children may not exist on all root types; guard it
		if not node.has_method("get_children"):
			continue
		for child in node.get_children():
			if child is Node:
				if String(child.name) == target_name:
					return child
				stack.append(child)

	return null

func _apply_audio_settings() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameManager.master_volume / 100.0))

# --- Fonctions de navigation ---

func _on_button_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Intro/main_layout_intro.tscn")
	menu_music.stop()

func _on_button_commandes_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu/commandes.tscn")

func _on_button_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu/credits.tscn")

# --- Fonctions Audio ---

func _on_check_button_toggled(toggled_on: bool) -> void:
	# toggled_on = true (Son Activé) -> is_muted = false
	GameManager.is_muted = not toggled_on
	
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, GameManager.is_muted)
	
	h_slider.visible = toggled_on
	
	if toggled_on:
		if GameManager.master_volume == 0:
			GameManager.master_volume = 100
		h_slider.value = GameManager.master_volume

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(nav_ok):
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control:
			if focused_control == button_jouer:
				_on_button_jouer_pressed()
			elif focused_control == button_commandes:
				_on_button_commandes_pressed()
			elif focused_control == button_credits:
				_on_button_credits_pressed()
			elif focused_control == check_button:
				check_button.button_pressed = not check_button.button_pressed
