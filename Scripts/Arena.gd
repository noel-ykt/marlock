class_name Arena
extends Control


var _score_table: ScoreTable
var _is_pinging = false
var _last_ping: int = 0

func _ready():
	_score_table = ResourceManager.load_scene(ResourceManager.Scene.UI_SCORE_TABLE)
	_score_table.refresh()
	_score_table.hide()
	$ScoreContainer.add_child(_score_table)
	GameState.register_debug_node($DebugPanel)
	if get_tree().is_network_server():
		$DebugPanel/Ping.text = "Ping: You are host"


func _input(event):
	if event is InputEventMouseMotion:
		$DebugPanel/MousePosition.text = "Mouse: %d, %d" % [event.position.x, event.position.y]

	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_toggle_score_table"):
			_score_table.refresh()
			_score_table.show()
		if Input.is_action_just_released("ui_toggle_score_table"):
			_score_table.hide()

func _process(_delta):
	$DebugPanel/FPS.text = "FPS: %d" % Engine.get_frames_per_second()

	if not get_tree().is_network_server():
		if not _is_pinging and (OS.get_ticks_msec() - _last_ping) > 100:
			_is_pinging = true
			_last_ping = OS.get_ticks_msec()
			rpc_id(1, "_ping")
	
remote func _ping():
	rpc_id(get_tree().get_rpc_sender_id(), "_pong")
	
remote func _pong():
	if _is_pinging:
		$DebugPanel/Ping.text = "Ping: %d ms" % (OS.get_ticks_msec() - _last_ping)
		_is_pinging = false
