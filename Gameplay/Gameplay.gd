extends Node

# attach this script to a map node with the following children:
# - Bullets : Node
# - Players : Node
# - HUD : instance of HUD.tscn
# - Camera : Camera2D with Camera.gd attached
# - Music : an AudioStreamPlayer
# - GameMode
#	- TDM : Node2D
#	- CTF : Node2D

onready var player_scene = preload('res://Player.tscn')

const MAX_HEALTH = 100

var globals
var input

# scene tree node containing the scene entities required for each game mode
var game_mode_nodes = {}
# the functionality and data for each game mode (scripts)
var game_mode_data = {}
var game_mode = null # an element of game_mode_data


func _ready():
	globals = get_node('/root/globals')
	input = preload('res://Utils/input.gd').new()
	
	if globals.settings.get_value('options', 'music', true):
		$Music.play()
	
	for n in $GameMode.get_children():
		game_mode_nodes[n.name] = n
		$GameMode.remove_child(n)
		game_mode_data[n.name] = load('res://Gameplay/' + n.name +'.gd').new()
		add_child(game_mode_data[n.name])
	
	input.reset_input_maps(len(globals.player_data))
	for p in globals.player_data:
		create_player(p)
	
	set_game_mode(globals.game_mode)
	game_mode.setup(globals.game_mode_details)
	

func set_game_mode(mode):
	assert mode in game_mode_nodes
	for n in $GameMode.get_children():
		$GameMode.remove_child(n)
	$GameMode.add_child(game_mode_nodes[mode])
	game_mode = game_mode_data[mode]
	print('game mode changed to: ' + mode)

func create_player(details):
	var prefix = 'p%d_' % details['num']
	var p = player_scene.instance()
	var mouse_look = bool(details['controls']['type'] == 'KEY')
	setup_player_control(prefix, details['controls'])
	p.setup(prefix, MAX_HEALTH, $Bullets, $Camera, mouse_look, details['team'])
	p.name = 'P%d' % details['num']
	$Players.add_child(p)

func setup_player_control(prefix, details):
	if details['type'] == 'KEY':
		input.assign_keyboard_mouse_input(prefix)
		
	elif details['type'] == 'GAMEPAD':
		input.assign_gamepad_input(prefix, details['index'])
		
	elif details['type'] == 'AI':
		print('not implemented')
	