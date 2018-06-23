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

onready var keyboard_player_scene = preload('res://Player/KeyboardPlayer.tscn')
onready var gamepad_player_scene = preload('res://Player/GamepadPlayer.tscn')
onready var AI_player_scene = preload('res://Player/AIPlayer.tscn')

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
	
	if globals.settings.get_value('options', 'music', true):
		$Music.play()
	
	if globals.settings.get_value('options', 'mouse_confined', true):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) # prevent going outside the game window
	Input.set_custom_mouse_cursor(preload('res://Assets/crosshairs.png'), Input.CURSOR_ARROW, Vector2(15, 15))
	
	for n in $GameMode.get_children():
		game_mode_nodes[n.name] = n
		$GameMode.remove_child(n)
		game_mode_data[n.name] = load('res://Gameplay/' + n.name +'.gd').new()
		add_child(game_mode_data[n.name])
	
	var keyboard_player = false # whether any players are using the keyboard + mouse
	for p in globals.player_data:
		if p.control == globals.KEYBOARD_CONTROL:
			keyboard_player = true
		create_player(p)
	
	if not keyboard_player and not globals.DEBUG: # don't hide the mouse in debug mode
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	set_game_mode(globals.game_mode)
	game_mode.setup(globals.game_mode_details)
	

func set_game_mode(mode):
	assert mode in game_mode_nodes
	for n in $GameMode.get_children():
		$GameMode.remove_child(n)
	$GameMode.add_child(game_mode_nodes[mode])
	game_mode = game_mode_data[mode]
	print('game mode changed to: ' + mode)

func create_player(config):
	var p = null
	if config.control == globals.KEYBOARD_CONTROL:
		p = keyboard_player_scene.instance()
	elif config.control == globals.GAMEPAD_CONTROL:
		p = gamepad_player_scene.instance()
	elif config.control == globals.AI_CONTROL:
		p = AI_player_scene.instance()
	p.init(config, $Camera, $Bullets)
	p.name = 'P%d' % config.num
	$Players.add_child(p)

	