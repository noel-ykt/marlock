class_name ScoreTable
extends Control

func _ready():
	pass

func refresh():
	var players = GameState.get_player_list()
	players.sort()
	$Players.clear()
	$Players.add_item(GameState.get_player_name() + " (You)")
	for player in players:
		$Players.add_item(player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
