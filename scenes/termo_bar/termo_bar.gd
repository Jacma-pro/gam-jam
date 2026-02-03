extends TextureProgressBar

func _ready() -> void:
	add_to_group("termo_bar")
	
	min_value = 0
	max_value = 100
	value = 50

func update_temperature(amount: float) -> void:
	# Add (fire gains) or subtract (ice gains)
	value += amount
	
	print("Score actuel : ", value, "/ 100")
	
	if value >= max_value:
		print("VICTOIRE DU FEU ! (La barre est pleine)")

	elif value <= min_value:
		print("VICTOIRE DE LA GLACE ! (La barre est vide)")
