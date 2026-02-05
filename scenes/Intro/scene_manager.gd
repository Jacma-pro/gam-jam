extends Node

# Références aux noeuds via le parent car ce script sera sur un noeud enfant
@onready var main_layout = get_parent()
@onready var animation_player = main_layout.get_node("AnimationPlayer")

@export var end_animation_timer: float = 5.0
@export var sudden_death_time: float = 60.0

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
			var v = get_viewport()
			if v:
				v.set_input_as_handled()

func pause_game() -> void:
	var pause_menu = PAUSE_MENU_SCENE.instantiate()
	# On ajoute le menu à la racine ou au MainLayout
	main_layout.add_child(pause_menu)
	get_tree().paused = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		print("SceneManager: Fin de l'intro, reprise du jeu")
		get_tree().paused = false

		# Lancer le timer de mort subite (dégâts doublés) après la reprise
		_start_sudden_death_timer()


func _start_sudden_death_timer() -> void:
	# create_timer returns a Timer object; we'll await its timeout and then call handler
	print("SceneManager: Timer de mort subite démarré pour ", sudden_death_time, " secondes")
	await get_tree().create_timer(sudden_death_time).timeout
	_on_sudden_death_timeout()


func _on_sudden_death_timeout() -> void:
	print("SceneManager: MORT SUBITE ! Dégâts doublés !")

	# Find players: prefer using groups if present
	var players: Array = []
	if get_tree().has_group("players"):
		players = get_tree().get_nodes_in_group("players")
	else:
		var p1 = _find_node_by_script("fire_player.gd")
		var p2 = _find_node_by_script("ice_player.gd")
		if p1:
			players.append(p1)
		if p2:
			players.append(p2)

	for p in players:
		if p:
			# set multiplier directly (players found by script/group are expected to have this var)
			p.damage_received_multiplier = 2.0

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
