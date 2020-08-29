extends Node

const DEFAULT_PORT = 10567

var MAX_PLAYERS = 12

var peer = null

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

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id):
	rpc_id(id, "register_player", player_name)

func _player_disconnected(id):
	unregister_player(id)

func _connected_ok():
	emit_signal("connection_succeeded")

func _server_disconnected():
	emit_signal("game_error", "Server disconnected")

func _connected_fail():
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")
	
remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print(id)
	players[id] = new_player_name
	emit_signal("player_list_changed")

func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

func get_player_list():
	return players.values()
	
func get_player_name():
	return player_name
	
func host_game(new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
