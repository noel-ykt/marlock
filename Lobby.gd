extends Control

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_end")
	gamestate.connect("game_error", self, "_on_game_error")
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/NameInput.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/NameInput.text = desktop_path[desktop_path.size() - 2]

func _on_connection_success():
	$Connect.hide()
	$Players.show()

func _on_connection_failed():
	$Connect/HostBtn.disabled = false
	$Connect/JoinBtn.disabled = false
	$Background/ErrorLabel.set_text("Connection Failed.")

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)
		
	$Players/StartBtn.disabled = not get_tree().is_network_server()

func _on_game_end():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/HostBtn.disabled = false
	$Connect/JoinBtn.disabled = false

func _on_game_error(errtxt):
	$Background/ErrorLabel.set_text(errtxt)
	$Connect/HostBtn.disabled = false
	$Connect/JoinBtn.disabled = false


func _on_HostBtn_pressed():
	if $Connect/NameInput.text == "":
		$Background/ErrorLabel.set_text("Invalid name!")
		return
	$Connect.hide()
	$Players.show()
	$Background/ErrorLabel.set_text("")
	
	var player_name = $Connect/NameInput.text
	gamestate.host_game(player_name)
	refresh_lobby()


func _on_JoinBtn_pressed():
	if $Connect/NameInput.text == "":
		$Background/ErrorLabel.text = "Invalid name!"
		return
	var ip = $Connect/IPInput.text
	if not ip.is_valid_ip_address():
		$Background/ErrorLabel.text = "Invalid IP address!"
		return
	$Background/ErrorLabel.text = ""
	$Connect/HostBtn.disabled = true
	$Connect/JoinBtn.disabled = true
	
	var player_name = $Connect/NameInput.text
	gamestate.join_game(ip, player_name)


func _on_StartBtn_pressed():
	gamestate.begin_game()
