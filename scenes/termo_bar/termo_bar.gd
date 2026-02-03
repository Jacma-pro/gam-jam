extends TextureProgressBar

func _ready() -> void:
	add_to_group("termo_bar")
	
	min_value = 0
	max_value = 100
	value = 50

func update_temperature(amount: float) -> void:
	# Add (fire gains) or subtract (ice gains)
	value += amount
	
	# Synchronise avec le GameManager si nécessaire, ou déclenche la victoire directement
	if GameManager:
		GameManager.temperature = value
		GameManager.check_win_condition()
	
	print("Score actuel : ", value, "/ 100")
