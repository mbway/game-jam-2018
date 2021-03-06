extends Node

const NAME = 'TDM'

var is_setup = false
var is_game_over = false
var details
var lives = []

# nodes
var nodes
var spawn_points
var players
var HUD
var camera

func setup(details):
	assert(not is_setup)
	self.details = details
	nodes = get_node('../GameMode/TDM')
	spawn_points = nodes.get_node('SpawnPoints')
	players = get_node('../Players')
	HUD = get_node('../HUD')
	camera = get_node('../Camera')
	lives = [details['max_lives'], details['max_lives']]
	is_setup = true


	#TODO: currently assuming 2 players
	var num_players = players.get_child_count()
	if num_players > 0:
		HUD.connect_player(players.get_child(0), 1)
	if num_players > 1:
		HUD.connect_player(players.get_child(1), 2)

	update_HUD()

	for p in players.get_children():
		p.connect('die', self, 'on_player_die', [p])
		if p.config.control != globals.Control.AI:
			camera.add_follow(p)
		spawn_player(p, false)


func on_player_die(player):
	var t = player.config.team - 1 # 1-based
	lives[t] = max(0, lives[t] - 1)
	update_HUD()
	if lives[t] == 0:
		#TODO: assuming only 2 teams
		HUD.show_game_over('Team %d Wins!' % ((1-t)+1))
	else:
		spawn_player(player, true)

func update_HUD():
	if is_setup:
		HUD.set_score_labels('T1: %d' % lives[0], 'T2: %d' % lives[1])

func spawn_player(p, delayed):
	if is_game_over:
		return

	var num_spawn_points = spawn_points.get_child_count()
	assert(num_spawn_points > 0)
	var spawn = spawn_points.get_child(randi() % num_spawn_points)
	# spawn offset helps prevent players from spawning directly on top of
	# one another and messing with the physics
	var spawn_offset = Vector2(rand_range(-1,1), rand_range(-1,1))
	if delayed:
		p.delayed_spawn(spawn.position + spawn_offset)
	else:
		p.spawn(spawn.position + spawn_offset)

func _on_game_over():
	get_tree().change_scene('res://MainMenu/MainMenu.tscn')
