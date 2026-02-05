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
@onready var menu_music: AudioStreamPlayer2D = $"../MenuMusic"

# Références aux nœuds (adaptées à la nouvelle structure)
@onready var button_jouer: Button = $ButtonJouer
@onready var button_commandes: Button = $ButtonCommandes
@onready var button_credits: Button = $ButtonCredits

# Les contrôles audio sont dans un autre conteneur (frère de celui-ci)
@onready var check_button: CheckButton = $"../AudioControl/CheckButtonOnOff"
@onready var h_slider: HSlider = $"../AudioControl/HSliderVolume"

@onready var hoverSFX: AudioStreamPlayer2D = $"../HoverSFX"
@onready var validSFX: AudioStreamPlayer2D = $"../ValidSFX"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Gestion de la musique persistante
	if get_tree().root.has_node("MenuMusic"):
		# Une musique joue déjà, on l'utilise
		var persistent_music = get_tree().root.get_node("MenuMusic")
		
		# Si on a une musique locale (du tscn), on la supprime pour ne pas avoir de doublon
		if menu_music and menu_music != persistent_music:
			menu_music.queue_free()
		
		# On met à jour la référence
		menu_music = persistent_music
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
	
	# Focus initial sur la barre de volume si possible, sinon le bouton audio
	if h_slider.visible:
		h_slider.grab_focus()
	else:
		check_button.grab_focus()

	# --- AJOUT: Connexion des effets sonores de survol (Souris + Clavier/Manette) ---
	# On connecte les signaux APRÈS le focus initial pour éviter de jouer le son au lancement
	var interactive_elements = [button_jouer, button_commandes, button_credits, check_button, h_slider]
	for element in interactive_elements:
		element.mouse_entered.connect(_play_hover_sfx)
		element.focus_entered.connect(_play_hover_sfx)
	# ---------------------------------------------------------------------------------

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

# --- Fonction utilitaire SFX ---

func _play_hover_sfx() -> void:
	if hoverSFX:
		hoverSFX.play()

# --- Fonctions de navigation ---

func _on_button_jouer_pressed() -> void:
	# On arrête et on nettoie la musique du menu avant de lancer le jeu
	if menu_music and is_instance_valid(menu_music):
		menu_music.stop()
		menu_music.queue_free()
	
	validSFX.play()
	await validSFX.finished
	get_tree().change_scene_to_file("res://scenes/Intro/main_layout_intro.tscn")

func _on_button_commandes_pressed() -> void:
	validSFX.play()
	await validSFX.finished
	get_tree().change_scene_to_file("res://scenes/Menu/commandes.tscn")

func _on_button_credits_pressed() -> void:
	validSFX.play()
	await validSFX.finished
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
				validSFX.play()
				check_button.button_pressed = not check_button.button_pressed
