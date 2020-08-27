extends Node

export (PackedScene) var Fireball

var _inputKey = KEY_F
var _ready_to_cast = false

func _ready():
	pass
	
func bindKey(inputKey):
	_inputKey = inputKey

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == _inputKey:
			print(_inputKey, " was pressed")
			_ready_to_cast = true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			if (_ready_to_cast):
				print("Mouse Left Click at: ", event.position)
				var player = get_node("/root/Main").get_node("Player")
				var move_vector = event.position - player.position
				cast(player.position, move_vector)
				_ready_to_cast = false

func cast(startPosition, vector):
	var fireball = Fireball.instance()
	fireball.position = startPosition;
	get_node("/root/Main").add_child(fireball)
	fireball.cast(vector)
