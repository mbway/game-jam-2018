extends Node


# Workflow:
#
# from the UI, a user chooses to host. other clients choose to join.
# Every time a new client connects successfully, they contact the server
# using RPC to transfer its local data by "registering". The server
# records the state and informs the new client of the other clients.
#
# After the host clicks start game, the server creates a host and 
# runs setup_game



const SERVER_ID = 1
const MAX_PEERS = 10
const DEFAULT_PORT = 5821

signal player_registered(id)

var my_player_name
var players = {} # ID:data
var game_started = false


func _ready():
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id):
	print('player connected ', id)

func _player_disconnected(id):
	players.erase(id)

func _connected_ok():
	# client is successfully connected
	rpc("register_player", get_tree().get_network_unique_id(), my_player_name)

func _connected_fail():
	print('connection failed')

func _server_disconnected():
	print('disconnected from server')

# remote => can be called by RPC
remote func register_player(id, info):
	if game_started:
		print('cannot join after game started')
		return
	if id in players:
		print('player already registered: ', id)
		return
	print('player registered ', id, info)
	players[id] = info
	if get_tree().is_network_server():
		# I am the server, and a new client has arrived. Inform them of the others
		# RPC to the new client only, informing to register my with ID 1
		rpc_id(id, "register_player", SERVER_ID, my_player_name)
		# RPC to the new client only, informing of other clients
		for peer_id in players:
			rpc_id(id, "register_player", peer_id, players[peer_id])
			rpc_id(peer_id, "register_player", id, info)
	emit_signal('player_registered', id)

remote func setup_game():
	var my_id = get_tree().get_network_unique_id()

	get_tree().set_pause(true) # start the game paused

	# load world
	var world = load('res://World.tscn').instance()
	get_node("/root").add_child(world)
	get_node("/root/Lobby").hide()

	# load my player
	var my_player = preload("res://Player.tscn").instance()
	my_player.set_name(str(my_id))
	my_player.set_network_master(my_id) # this client has full control over this node
	get_node("/root/World/Players").add_child(my_player)

	# Load other players
	for p in players:
		var player = preload("res://Player.tscn").instance()
		player.set_name(str(p))
		get_node("/root/World/Players").add_child(player)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring
	if not get_tree().is_network_server():
		rpc_id(SERVER_ID, "setup_finished", my_id)

# called by each client. Start the game one everyone ready
var players_done = []
remote func setup_finished(peer_id):
    assert(get_tree().is_network_server()) # only execute on the server
    assert(peer_id in players) # player is known
    assert(not peer_id in players_done) # not already finished

    players_done.append(peer_id)

    if players_done.size() == players.size():
        rpc("start_game_all_finished") # send to everyone

remote func start_game_all_finished():
    get_tree().set_pause(false)
    game_started = true


func host_game(player_name):
	my_player_name = player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

	players[SERVER_ID] = my_player_name
	emit_signal('player_registered', SERVER_ID, my_player_name)

func join_game(ip, player_name):
	print('joining game ', ip)
	my_player_name = player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func server_start_game():
	assert(get_tree().is_network_server())
	for p in players:
		rpc_id(p, "setup_game")
	setup_game()
