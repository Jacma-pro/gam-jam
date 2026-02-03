extends Node

# Références aux noeuds via le parent car ce script sera sur un noeud enfant
@onready var main_layout = get_parent()
@onready var animation_player = main_layout.get_node("AnimationPlayer")

const PAUSE_MENU_SCENE = preload("res://scenes/Menu/pause_menu.tscn")
const OVER_MENU_SCENE = preload("res://scenes/Menu/over_menu.tscn")

func _ready() -> void:
	print("SceneManager: Prêt et configuré en mode ALWAYS")
	
	# 1. Connexion au GameManager
	if GameManager:
		if not GameManager.game_over.is_connected(_on_game_over):
			GameManager.game_over.connect(_on_game_over)
			print("SceneManager: Signal game_over connecté")
	
	# 2. Mise en pause initiale pour l'intro
	# Comme MainLayout est en mode normal, get_tree().paused = true va tout arrêter (joueurs compris)
	get_tree().paused = true
	print("SceneManager: Jeu mis en pause pour l'intro")
	
	# 3. Connexion Animation
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	# Gestion de la pause manuelle
	if Input.is_action_just_pressed("pause"):
		if not get_tree().paused:
			pause_game()

func pause_game() -> void:
	var pause_menu = PAUSE_MENU_SCENE.instantiate()
	# On ajoute le menu à la racine ou au MainLayout
	main_layout.add_child(pause_menu)
	get_tree().paused = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		print("SceneManager: Fin de l'intro, reprise du jeu")
		get_tree().paused = false

func _on_game_over(winner_name: String) -> void:
	print("SceneManager: VICTOIRE détectée pour ", winner_name)
	
	var over_menu = OVER_MENU_SCENE.instantiate()
	# Ajout direct à la racine de l'arbre pour éviter les problèmes d'héritage de pause ou de visibilité
	get_tree().root.add_child(over_menu)
	
	over_menu.set_winner(winner_name)
	
	# On remet le jeu en pause pour tout figer
	get_tree().paused = true
	print("SceneManager: Jeu mis en pause (paused = ", get_tree().paused, ")")
