extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	new_game()
	
func _input(event):
	pass

func new_game():
	$Player.start($StartPosition.position)

func game_over():
	pass
