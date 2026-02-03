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
        print("VICTOIRE FEU !")
        emit_signal("game_over", "Fire Player")
        get_tree().paused = true
    elif temperature <= 0:
        print("VICTOIRE GLACE !")
        emit_signal("game_over", "Ice Player")
        get_tree().paused = true