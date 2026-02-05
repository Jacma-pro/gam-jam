extends Node2D

@onready var menu_music: AudioStreamPlayer2D = $MusicMenu2

@onready var home_return: TextureRect = $homeReturn

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
			push_warning("Credits: MusicMenu2 node not found")
	if home_return:
		home_return.gui_input.connect(_on_home_return_gui_input)

func _on_home_return_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if menu_music:
			menu_music.queue_free()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
