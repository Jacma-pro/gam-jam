extends Node

# Références aux noeuds via le parent car ce script sera sur un noeud enfant
@onready var main_layout = get_parent()
@onready var animation_player = main_layout.get_node("AnimationPlayer")

@export var end_animation_timer: float = 5.0

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

func _unhandled_input(event: InputEvent) -> void:
	# Gestion de la pause manuelle
	# On utilise _unhandled_input pour que si le MenuPause consomme l'événement, on ne le re-traite pas ici
	if event.is_action_pressed("pause"):
		if not get_tree().paused:
			pause_game()
			# On consomme l'événement pour éviter qu'il ne remonte ailleurs
			get_viewport().set_input_as_handled()

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

	# Make sure the tree is not paused so the death animation can play
	get_tree().paused = false

	# Determine which player node is the loser based on the winner name
	var lower = String(winner_name).to_lower()
	var loser_script := "ice_player.gd"
	if lower.find("ice") != -1:
		loser_script = "fire_player.gd"

	var loser = _find_node_by_script(loser_script)
	if loser and loser.has_method("die"):
		loser.die()
		print("SceneManager: Mort déclenchée pour le joueur perdant")

	# wait the configured end animation timer before showing the over menu
	await get_tree().create_timer(end_animation_timer).timeout

	var over_menu = OVER_MENU_SCENE.instantiate()
	# Ajout direct à la racine de l'arbre pour éviter les problèmes d'héritage de pause ou de visibilité
	get_tree().root.add_child(over_menu)

	over_menu.set_winner(winner_name)

	# On remet le jeu en pause pour tout figer
	get_tree().paused = true
	print("SceneManager: Jeu mis en pause (paused = ", get_tree().paused, ")")


func _find_node_by_script(script_basename: String) -> Node:
	# Iterative DFS over scene tree to find a node whose script resource path ends with the given basename
	var stack: Array = []
	stack.append(get_tree().root)

	while stack.size() > 0:
		var node = stack.pop_back()
		for child in node.get_children():
			if child is Node:
				var sc = child.get_script()
				if sc and typeof(sc) == TYPE_OBJECT and sc.resource_path.ends_with(script_basename):
					return child
				stack.append(child)

	return null
