extends Node

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 4

# Name for my player
var player_name = "The Warrior"

# Names for remote players in id:name format
var players = {}

var world = null

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


# Callback from SceneTree
func _player_connected(id):
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	if get_tree().is_network_server():
		# TODO
		if has_node("/root/world1"): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions

remote func register_player(id, new_player_name):
	if get_tree().is_network_server():
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	players[id] = new_player_name
	emit_signal("player_list_changed")

remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points, player_teams):
	# Change scene
	world = load("res://MapStage1.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()

	var player_scene = load("res://HeroBody.tscn")
	
	for player_id in spawn_points:
		var player = player_scene.instance()
		player.spawn_position = _get_spawn_position(spawn_points[player_id])
		player.team = player_teams[player_id]
		player.set_network_master(player_id)
		
		if player_id == get_tree().get_network_unique_id():
			player.hero_name = player_name
		else:
			player.hero_name = players[player_id]
			player.get_node("Camera2D").queue_free()

		world.get_node("players").add_child(player)
		MapState.register_hero(player_id, player)

#	for p_id in spawn_points:
#		var spawn_name = "spawn_points/spawn" + str(spawn_points[p_id])
#		var spawn_pos = world.get_node(spawn_name).position
#		var player = player_scene.instance()
#
#		player.hero_name = (str(p_id)) # Use unique ID as node name
#		player.spawn_position = spawn_pos
#		player.set_network_master(p_id) #set unique id as master
#
#		if p_id == get_tree().get_network_unique_id():
#			# If node for this peer id, set name
#			#player.set_player_name(player_name)
#			player.hero_name = player_name
#			#MapState.master_hero = player
#		else:
#			# Otherwise set name from peer
#			#player.set_player_name(players[p_id])
#			player.hero_name = players[p_id]
#			player.get_node("Camera2D").queue_free()
#
#		world.get_node("players").add_child(player)
#		MapState.register_hero(p_id, player)

	# TODO
	# Set up score
	#world.get_node("score").add_player(get_tree().get_network_unique_id(), player_name)
	#for pn in players:
	#	world.get_node("score").add_player(pn, players[pn])

	if not get_tree().is_network_server():
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func begin_game():
	assert(get_tree().is_network_server())
	
	var player_teams = {}
	var teams_in_order = _generate_random_teams()
	var tmp = 0
	for p in players:
		player_teams[p] = teams_in_order[tmp]
		tmp += 1
		
	player_teams[1] = teams_in_order[tmp]

	# Create a dictionary with peer id and respective spawn points
	# could be improved by randomizing
	var blue_points = [1, 2]
	var red_points = [3, 4]
	var spawn_points = {}
	
	if teams_in_order[tmp] == 'red':
		spawn_points[1] = red_points.pop_front()
	if teams_in_order[tmp] == 'blue':
		spawn_points[1] = blue_points.pop_front()
	
	for p in players:
		if player_teams[p] == 'red':
			spawn_points[p] = red_points.pop_front()
		if player_teams[p] == 'blue':
			spawn_points[p] = blue_points.pop_front()
	
#	spawn_points[1] = 1 # Server in spawn point 1
#	var spawn_point_idx = 2
#	for p in players:
#		spawn_points[p] = spawn_point_idx
#		spawn_point_idx += 1
	# Call to pre-start game with the spawn points
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points, player_teams)
	pre_start_game(spawn_points, player_teams)


func end_game():
	if has_node("/root/world1"): # Game is in progress
		# End it
		get_node("/root/world1").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking


func _generate_random_teams():
	var players_count = players.size() + 1
	assert(players_count > 0)
	assert(players_count <= 4)
	var results = []
	
	if players_count == 1:
		if randi() % 2 == 0:
			results.append('red')
		else:
			results.append('blue')
			
	if players_count == 2:
		if randi() % 2 == 0:
			results.append('red')
			results.append('blue')
		else:
			results.append('blue')
			results.append('red')
	
	if players_count == 3:
		for i in range(3):
			if randi() % 2 == 0:
				results.append('red')
			else:
				results.append('blue')
		
		if results[0] == results[1] and results[1] == results[2]:
			var tmp = results[0]
			if tmp == 'red': tmp = 'blue'
			else: tmp = 'red'
			results[randi() % 3] = tmp
	
	if players_count == 4:
		var count_r = results.count('red')
		var count_b = results.count('blue')
		while count_r == 0 or count_r != count_b:
			for i in range(4):
				if randi() % 2 == 0:
					results.append('red')
				else:
					results.append('blue')
			count_r = results.count('red')
			count_b = results.count('blue')
	
	return results


func _get_spawn_position(number):
	assert(world != null)
	var spawn_name = "spawn_points/spawn" + str(number)
	return world.get_node(spawn_name).position




