extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const PAUSE_MENU_SCENE = preload("res://scenes/Menu/pause_menu.tscn")
const OVER_MENU_SCENE = preload("res://scenes/Menu/over_menu.tscn")

func _ready() -> void:
	print("MainLayoutIntro: _ready appelé")
	
	# Force le mode Pausable sur la section de jeu pour être sûr que les joueurs s'arrêtent
	var game_section = get_node_or_null("VBoxContainer/GameSection")
	if game_section:
		game_section.process_mode = Node.PROCESS_MODE_PAUSABLE
		print("MainLayoutIntro: GameSection mis en mode PAUSABLE")
	else:
		print("MainLayoutIntro: ATTENTION - GameSection introuvable")

	# Vérifie que le GameManager est accessible (Autoload)
	if GameManager:
		print("MainLayoutIntro: GameManager trouvé")
		if not GameManager.game_over.is_connected(_on_game_over):
			GameManager.game_over.connect(_on_game_over)
			print("MainLayoutIntro: Signal game_over connecté")
	else:
		print("MainLayoutIntro: ERREUR - GameManager introuvable")

	# ... suite du code

func _on_game_over(winner_name: String) -> void:
	print("MainLayoutIntro: _on_game_over appelé avec vainqueur : ", winner_name)
	var over_menu = OVER_MENU_SCENE.instantiate()
	add_child(over_menu)
	print("MainLayoutIntro: OverMenu instancié et ajouté")
	
	# Le script est maintenant sur la racine, on peut appeler la fonction directement
	over_menu.set_winner(winner_name)
	
	get_tree().paused = true
	print("MainLayoutIntro: Jeu mis en pause")
