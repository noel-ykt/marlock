extends Control


func _generate_name():
	randomize()
	var names = [
		'Alastor', 'Alatar', 'Albus', 'Aletheia', 'Allanon', 'Azathoth',
		'Barid', 'Belgarath', 'Cthulhu', 'Dagoth', 'Divayth', 'Faegan',
		'Gandalf', 'Gwydion', 'Harry', 'Hydra', 'Hypnos', 'Ishamael', 'Jafar',
		'Kaajh\'Kaalbh', 'Kingsley', 'Lews', 'Logain', 'Merlin', 'Mr O\'Roarke',
		'Mustrum', 'Nyarlathotep', 'Oz', 'Pallando', 'Paul', 'Prospero',
		'Radagast', 'Raistlin', 'Rand Al\'Thor', 'Richard', 'Rincewind',
		'Saruman', 'Sauron', 'Severus', 'Shabbith-Ka', 'Shub-Niggurath',
		'Simon', 'Tayschrenn', 'Thoth-amon', 'Tretiak', 'Voldemort', 'Wigg',
		'Xexanoth', 'Yidhra', 'Yog-Sothoth'
	]
	var epithets = [
		'Anxious', 'Architect', 'Bad', 'Beast', 'Bodyguard', 'Butcher',
		'Common', 'Concerned', 'Cook', 'Crooked', 'Dapper', 'Decent',
		'Disguised', 'Dull', 'Early', 'Enchanted', 'Executioner', 'Fake King',
		'Fox', 'Genuine', 'Giant', 'Hasty', 'Hawk', 'Hermit', 'Hollow',
		'Hospitable', 'Idealist', 'Jester', 'Jigsaw', 'Just', 'Juvenile',
		'Late', 'Lonely', 'Loyal Heart', 'Loyal', 'Mage', 'Marked', 'Mild',
		'Mouse', 'Mute', 'Naughty', 'Overprotective', 'Plain', 'Proud', 'Rat',
		'Rogue', 'Snowflake', 'Stalker', 'Stout', 'Strict', 'Surgeon',
		'True King', 'Thirsty', 'Watcher', 'Weak', 'Whimp', 'Wizard'
	]
	var fullname = "%s The %s" % [
		names[randi() % names.size()],
		epithets[randi() % epithets.size()]
	]
	return fullname


func _ready():
	var _err

	var resolution = OS.get_screen_size()
	$DebugPanel.add_label("OSResolution", "OS resolution: %dx%d" % [resolution.x, resolution.y], Label.ALIGN_RIGHT)
	resolution = get_viewport_rect().size
	$DebugPanel.add_label("GameResolution", "Game resolution: %dx%d" % [resolution.x, resolution.y], Label.ALIGN_RIGHT)

	_err = GameState.connect("connection_succeeded", self, "_on_connection_success")
	_err = GameState.connect("connection_failed", self, "_on_connection_failed")
	_err = GameState.connect("player_list_changed", self, "refresh_lobby")
	_err = GameState.connect("game_ended", self, "_on_game_end")
	_err = GameState.connect("game_error", self, "_on_game_error")
	$Connect/NameInput.text = _generate_name()


func _on_connection_success():
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/HostBtn.disabled = false
	$Connect/JoinBtn.disabled = false
	$Background/ErrorLabel.set_text("Connection Failed.")


func refresh_lobby():
	var players = GameState.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(GameState.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)
	
	if not get_tree().is_network_server():
		$Players/StartBtn.hide()


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
	GameState.host_game(player_name)
	refresh_lobby()


func _on_JoinBtn_pressed():
	if $Connect/NameInput.text == "":
		$Background/ErrorLabel.text = "Invalid name!"
		return
	var ip = $Connect/IPInput.text if $Connect/IPInput.text else "127.0.0.1"
	if not ip.is_valid_ip_address():
		$Background/ErrorLabel.text = "Invalid IP address!"
		return
	$Background/ErrorLabel.text = ""
	$Connect/HostBtn.disabled = true
	$Connect/JoinBtn.disabled = true
	
	var player_name = $Connect/NameInput.text
	GameState.join_game(ip, player_name)


func _on_StartBtn_pressed():
	GameState.begin_game()


func _on_RefreshNameBtn_pressed():
	$Connect/NameInput.text = _generate_name()
