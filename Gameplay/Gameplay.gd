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

const keyboard_player_scene = preload('res://Player/KeyboardPlayer.tscn')
const gamepad_player_scene = preload('res://Player/GamepadPlayer.tscn')
const AI_player_scene = preload('res://Player/AIPlayer.tscn')

const MAX_HEALTH = 100

onready var G = globals
var input

# scene tree node containing the scene entities required for each game mode {mode: instance}
var game_mode_nodes = {}
# the functionality and data for each game mode (scripts) {mode: script}
var game_mode_data = {}
var game_mode = null # an element of game_mode_data

# whether there is a player using the keyboard and mouse. If not, then the cursor can be hidden.
var keyboard_player = false


func _ready():
	G.log('Game started: %s' % get_tree().get_current_scene().get_name())
	
	# store the game mode specific nodes away in a data structure and remove them from the tree for now
	for n in $GameMode.get_children():
		game_mode_nodes[n.name] = n
		$GameMode.remove_child(n)
		game_mode_data[n.name] = load('res://Gameplay/' + n.name +'.gd').new()
		add_child(game_mode_data[n.name])

	for p in G.player_data:
		if p.control == G.KEYBOARD_CONTROL:
			keyboard_player = true
		create_player(p)


	set_game_mode(G.game_mode)
	game_mode.setup(G.game_mode_details)
	
	_on_settings_changed()
	G.settings.connect('settings_changed', self, '_on_settings_changed')


func set_game_mode(mode):
	assert mode in game_mode_nodes
	for n in $GameMode.get_children():
		$GameMode.remove_child(n)
	$GameMode.add_child(game_mode_nodes[mode])
	game_mode = game_mode_data[mode]
	G.log('game mode changed to: ' + mode)

func create_player(config):
	var p = null
	if config.control == G.KEYBOARD_CONTROL:
		p = keyboard_player_scene.instance()
	elif config.control == G.GAMEPAD_CONTROL:
		p = gamepad_player_scene.instance()
	elif config.control == G.AI_CONTROL:
		p = AI_player_scene.instance()
	var nav = null if not has_node('Nav') else $Nav # TODO: make mandatory once pathfinding is finished and applied to all maps
	p.init(config, $Camera, $Bullets, nav)
	p.name = 'P%d' % config.num
	$Players.add_child(p)

	if G.settings.get('inspect_window'):
		var node_name = 'Player %d' % config.num
		# only the interesting attributes
		var attrs = ['current_weapon',
					'weapon_angle',
					'move_direction',
					'fire_pressed',
					'fire_held',
					'last_jump_pressed_ms',
					'jump_released',
					'max_health',
					'health',
					'alive',
					'invulnerable',
					'velocity',
					'last_jump_ms',
					'was_on_floor',
					'left_floor_ms',
					'mid_air_jumps']
		if config.control == G.KEYBOARD_CONTROL:
			attrs += ['left_pressed', 'right_pressed']
		for attr in attrs:
			$Watch.add_watch(node_name, p, attr)

func _on_settings_changed():
	if G.settings.get('music'):
		$Music.play()
	else:
		$Music.stop()

	var term_enabled = G.settings.get('terminal_enabled')
	if term_enabled and not has_node('Terminal'):
		add_child(preload('res://UI/Terminal.tscn').instance())
	elif not term_enabled and has_node('Terminal'):
		$Terminal.queue_free()

	var cursor_visible = keyboard_player or G.settings.get('debug') # don't hide the mouse in debug mode
	var mode
	if G.settings.get('mouse_confined'):
		# captured is the same as confined except also hidden
		mode = Input.MOUSE_MODE_CONFINED if cursor_visible else Input.MOUSE_MODE_CAPTURED
	else:
		mode = Input.MOUSE_MODE_VISIBLE if cursor_visible else Input.MOUSE_MODE_HIDDEN
	Input.set_mouse_mode(mode)
	#TODO: there is a bug where the cursor is incorrect after returning to the menu and starting another game
	Input.set_custom_mouse_cursor(preload('res://Assets/crosshairs.png'), Input.CURSOR_ARROW, Vector2(15, 15))


	if G.settings.get('inspect_window'):
		var w = preload('res://UI/DebugWatcher.tscn').instance()
		w.name = 'Watch'
		add_child(w)
	elif has_node('Watch'):
		$Watch.queue_free()
	
	#TODO: remove check once Nav is compulsory
	if has_node('Nav'):
		$Nav.visible = G.settings.get('nav_visible')
		if $Nav.visible:
			$Nav.update() # redraw
		
	OS.set_window_fullscreen(G.settings.get('full_screen'))
	
	Engine.time_scale = G.settings.get('game_speed')

