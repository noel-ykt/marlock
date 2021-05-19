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

	var resolution = OS.get_screen_size()
	$DebugPanel.add_label("OSResolution", "OS resolution: %dx%d" % [resolution.x, resolution.y], Label.ALIGN_RIGHT)
	resolution = get_viewport_rect().size
	$DebugPanel.add_label("GameResolution", "Game resolution: %dx%d" % [resolution.x, resolution.y], Label.ALIGN_RIGHT)
	$DebugPanel.add_label("MousePosition", "Mouse x: 0, y: 0", Label.ALIGN_RIGHT)
	$DebugPanel.add_label("Ping", "Ping: 0", Label.ALIGN_RIGHT)
	$DebugPanel.add_label("FPS", "FPS: 0", Label.ALIGN_RIGHT)
	if get_tree().is_network_server():
		$DebugPanel.set_label_text("Ping", "Ping: You are host")


func _input(event):
	if event is InputEventMouseMotion:
		$DebugPanel.set_label_text("MousePosition", "Mouse x: %d, y: %d" % [event.position.x, event.position.y])

	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_toggle_score_table"):
			_score_table.refresh()
			_score_table.show()
		if Input.is_action_just_released("ui_toggle_score_table"):
			_score_table.hide()

func _process(_delta):
	$DebugPanel.set_label_text("FPS", "FPS: %d" % Engine.get_frames_per_second())

	if not get_tree().is_network_server():
		if not _is_pinging and (OS.get_ticks_msec() - _last_ping) > 100:
			_is_pinging = true
			_last_ping = OS.get_ticks_msec()
			rpc_id(1, "_ping")
	
remote func _ping():
	rpc_id(get_tree().get_rpc_sender_id(), "_pong")
	
remote func _pong():
	if _is_pinging:
		$DebugPanel.set_label_text("Ping", "Ping: %d ms" % (OS.get_ticks_msec() - _last_ping))
		_is_pinging = false

func _on_lava_body_entered(body):
	if body.is_in_group("players"):
		body.add_effect("lava")


func _on_lava_body_exited(body):
	if body.is_in_group("players"):
		body.remove_effect("lava")
