extends Node

const DEFAULT_PORT = 10567

var MAX_PLAYERS = 8
var peer = null

# DEBUG SECTION
var DEBUG_MODE = true
var _debug_nodes: Array = []

func register_debug_node(node: Node):
	if node and "visible" in node:
		node.visible = DEBUG_MODE
		_debug_nodes.append(node)
		print("registered %d" % node.get_instance_id())

func unregister_debug_node(node: Node):
	if node in _debug_nodes:
		_debug_nodes.erase(node)
		print("unregistered %d" % node.get_instance_id())

func _input(event):
	if event is InputEventKey:
		if Input.is_action_pressed("ui_toggle_debug"):
			DEBUG_MODE = !DEBUG_MODE
			for node in _debug_nodes:
				node.visible = DEBUG_MODE

# Name for my player.
var player_name = "Player 1"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _ready() -> void:
	var _err
	_err = get_tree().connect("network_peer_connected", self, "_player_connected")
	_err = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id) -> void:
	rpc_id(id, "register_player", player_name)


func _player_disconnected(id) -> void:
	if has_node("/root/Arena"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
	else:
		unregister_player(id)


func _connected_ok() -> void:
	emit_signal("connection_succeeded")


func _server_disconnected() -> void:
	emit_signal("game_error", "Server disconnected")


func _connected_fail() -> void:
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")
	
	
remote func register_player(new_player_name) -> void:
	var id = get_tree().get_rpc_sender_id()
	print(id)
	players[id] = new_player_name
	emit_signal("player_list_changed")


func unregister_player(id) -> void:
	players.erase(id)
	emit_signal("player_list_changed")


func get_player_list() -> Array:
	return players.values()
	
	
func get_player_name() -> String:
	return player_name
	
	
func host_game(new_player_name) -> void:
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	
func join_game(ip, new_player_name) -> void:
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	
	
func begin_game() -> void:
	assert(get_tree().is_network_server())
	
	var spawn_points = {}
	spawn_points[1] = {'id': 0, 'name': player_name}
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = {'id': spawn_point_idx, 'name': players[p]}
		spawn_point_idx += 1
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)
	pre_start_game(spawn_points)
	
	
func end_game() -> void:
	if has_node("/root/Arena"):
		get_node("/root/Arena").queue_free()
	emit_signal("game_ended")
	players.clear()
	
	
remote func pre_start_game(spawn_points) -> void:
	get_tree().set_pause(true)
	var world = ResourceManager.load_scene(ResourceManager.Scene.ARENA)
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()
	
	var player_scene = ResourceManager.load_scene(ResourceManager.Scene.PLAYER, false)
	var spawnPoints = world.get_node("SpawnPoint")
	for p_id in spawn_points:
		var spawn_pos: Vector2 = spawnPoints.get_node(str(spawn_points[p_id].id)).position + spawnPoints.position
		var player = player_scene.instance()
		
		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position = spawn_pos
		player.set_inertia(0)
		player.set_network_master(p_id) #set unique id as master.
		player.set_nickname(spawn_points[p_id].name)
		
		world.get_node("Players").add_child(player)
		
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		# If network master start game if you are only one player
		post_start_game()
		
	
remote func post_start_game() -> void:
	get_tree().set_pause(false) # Unpause and unleash the game!
	
	
remote func ready_to_start(id) -> void:
	assert(get_tree().is_network_server())
	
	if not id in players_ready:
		players_ready.append(id)
	
	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()
