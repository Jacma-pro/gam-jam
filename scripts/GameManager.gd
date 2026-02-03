extends Node

signal temperature_changed(new_value)
signal game_over(winner_name)

var temperature: float = 50.0 

func change_temperature(amount: float):
	temperature += amount
	
	temperature = clamp(temperature, 0, 100)
	
	emit_signal("temperature_changed", temperature)
	
	check_win_condition()

func check_win_condition():
	if temperature >= 100:
		print("GameManager: VICTOIRE FEU ! Emission signal")
		emit_signal("game_over", "Fire Player")
		get_tree().call_deferred("set_paused", true)
	elif temperature <= 0:
		print("GameManager: VICTOIRE GLACE ! Emission signal")
		emit_signal("game_over", "Ice Player")
		get_tree().call_deferred("set_paused", true)
