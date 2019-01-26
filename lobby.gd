extends Control

func _ready():
	GameState.connect("connection_failed", self, "_on_connection_failed")
	GameState.connect("connection_succeeded", self, "_on_connection_success")
	GameState.connect("player_list_changed", self, "refresh_lobby")
	GameState.connect("game_ended", self, "_on_game_ended")
	GameState.connect("game_error", self, "_on_game_error")


func _on_button_host_pressed():
	var player_name = get_node("connect/line_name").text
	if player_name == "":
		get_node("connect/label_error").text = "Invalid name!"
		return
	
	get_node("connect/label_error").text = ""
	get_node("connect").hide()
	get_node("players").show()
	
	GameState.host_game(player_name)
	refresh_lobby()


func _on_button_join_pressed():
	var player_name = get_node("connect/line_name").text
	if player_name == "":
		get_node("connect/label_error").text = "Invalid name!"
		return
		
	var ip = get_node("connect/line_ip").text
	if not ip.is_valid_ip_address():
		get_node("connect/label_error").text = "Invalid IP address!"
		return
		
	get_node("connect/label_error").text = "Connecting..."
	get_node("connect/button_join").disabled = true
	get_node("connect/button_host").disabled = true
	
	GameState.join_game(ip, player_name)
	

func _on_connection_success():
	get_node("connect/label_error").text = ""
	get_node("connect/button_host").disabled = false
	get_node("connect/button_join").disabled = false
	get_node("connect").hide()
	get_node("players").show()

func _on_connection_failed():
	get_node("connect/button_host").disabled = false
	get_node("connect/button_join").disabled = false
	get_node("connect/label_error").text = "Connection failed."


func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("players").hide()
	get_node("connect/button_host").disabled = false
	get_node("connect/button_join").disabled = false

func _on_game_error(errtxt):
	_on_game_ended()
	get_node("error").dialog_text = errtxt
	get_node("error").popup_centered_minsize()


func refresh_lobby():
	get_node("players/connected_players").clear()
	get_node("players/connected_players").add_item(
		GameState.get_player_name() + " (You)")
	
	var players = GameState.get_player_list()
	players.sort()
	for player in players:
		get_node("players/connected_players").add_item(player)
	
	get_node("players/button_start").disabled = not get_tree().is_network_server()



func _on_button_start_pressed():
	GameState.begin_game()
