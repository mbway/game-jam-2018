extends Control

onready var G = globals

signal back

const player_panel_scene = preload('res://MainMenu/PlayerPanel.tscn')

# note: this doesn't belong in globals because it is only used during the main menu
# not a dictionary because order is important
var maps = [
	{
		'path': 'res://Maps/UFO/UFO.tscn',
		'name' : 'UFO',
		'screenshot' : preload('res://Maps/UFO/UFO.png'),
	},
	{
		'path': 'res://Maps/Ship/Ship.tscn',
		'name' : 'Ship',
		'screenshot' : preload('res://Maps/Ship/Ship.png'),
	},
	{
		'path': 'res://Maps/Obelisk/Obelisk.tscn',
		'name' : 'Obelisk',
		'screenshot' : preload('res://Maps/Obelisk/Obelisk.png'),
	},
	{
		'path': 'res://Maps/TestMap/TestMap.tscn',
		'name' : 'Test Map',
		'screenshot' : preload('res://Maps/TestMap/TestMap.png'),
	},
	{
		'path': 'res://Maps/AIStressTest/AIStressTest.tscn',
		'name' : 'AI Stress Test',
		'screenshot' : preload('res://Maps/AIStressTest/AIStressTest.png'),
	},
	{
		'path': 'res://Maps/Forts/Forts.tscn',
		'name' : 'Forts',
		'screenshot' : preload('res://Maps/Forts/Forts.png'),
	}
]
var game_modes = [
	['TDM', 'Team Death Match'],
	['Survival', 'Survival']
]
var input_methods = [] # [{'type': globals.CONTROL_TYPE, 'name':#, 'index':(only with GAMEPAD)}]
var teams = ['Team 1', 'Team 2']

var preset_colors = [
	Color(0.98, 0.94, 0.1),
	Color(0.4, 0.4, 0.9),
	Color(0.3, 0.98, 0.16),
	Color(0.98, 0.16, 0.78),
	Color(0.1, 0.98, 0.95),
	Color(0.98, 0.1, 0.1)
]

var selected_map = 0


# handles to UI nodes
var game_mode_dropdown
var map_screenshot
var map_title
var game_mode_options = []
var players


func _ready():
	game_mode_dropdown = find_node('GameMode', true)
	for m in game_modes:
		game_mode_dropdown.add_item(m[1])
		var options = find_node(m[0] + 'Options')
		game_mode_options.append(options)
		options.hide()
	_on_GameMode_item_selected(0)

	map_screenshot = find_node('Screenshot', true)
	map_title = find_node('MapTitle', true)
	select_map(0)

	players = find_node('PlayerList')

	input_methods.append({'type' : G.Control.KEYBOARD, 'name' : 'Keyboard + Mouse'})
	for g in Input.get_connected_joypads():
		input_methods.append({'type' : G.Control.GAMEPAD, 'index' : g, 'name' : 'Gamepad %d' % g})
	input_methods.append({'type' : G.Control.AI, 'name' : 'AI'})

	# add a player for each non-AI input method
	for _i in range(len(input_methods) - 1):
		_add_player()



# change the selected map index and reflect the change in the UI
func select_map(index):
	var n = len(maps)
	selected_map = Math.positive_modulo(index, n)
	var map = maps[selected_map]
	map_title.text = '%s   (%d/%d)' % [map['name'], selected_map+1, n]
	map_screenshot.texture = map['screenshot']



func _on_StartButton_pressed():
	#TODO: validate that the configuration makes sense
	# - no two players have the same input
	# - there is at least one player

	var map_path = maps[selected_map]['path']
	G.game_mode = game_modes[game_mode_dropdown.selected][0]

	var players_list = players.get_children()
	G.player_data.clear()
	for i in range(len(players_list)):
		var p = players_list[i]
		var details = p.get_player_details()

		var config = G.PlayerConfig.new()
		config.num = i + 1 # 1-based
		config.name = details["name"]
		config.team = details["team"] + 1 # 1-based
		if details["color"] != Color(255, 255, 255):
			config.color = details["color"]

		var selected_input = input_methods[details["input_method"]]
		config.control = selected_input['type']
		if config.control == G.Control.GAMEPAD:
			config.gamepad_id = selected_input['index']

		G.player_data.append(config)

	if G.game_mode == 'TDM':
		var options = game_mode_options[game_mode_dropdown.selected]
		G.game_mode_details = {
			'max_lives' : options.get_node('MaxLives').value
		}
	else:
		print('not implemented')

	get_tree().change_scene(map_path)


func _process(delta):
	$Background.region_rect.position.x += delta * 500
	$Background.region_rect.position.y -= delta * 20

	if Input.is_action_just_pressed('ui_left'):
		select_map(selected_map - 1)
	elif Input.is_action_just_pressed('ui_right'):
		select_map(selected_map + 1)

func _on_PrevMap_pressed():
	select_map(selected_map - 1)
func _on_NextMap_pressed():
	select_map(selected_map + 1)

func _on_BackButton_pressed():
	emit_signal('back')


func _on_GameMode_item_selected(ID):
	for o in game_mode_options:
		o.hide()
		o.set_process(false)
	var options = game_mode_options[ID]
	options.show()
	options.set_process(true)



func _add_player():
	var player = player_panel_scene.instance()
	var n = players.get_child_count()
	var name = 'Player ' + str(n + 1)
	var default_team = n % len(teams)
	var default_input_method

	# initially assign the lowest index into input_methods which has not yet been assigned to a player
	var available_indices = range(len(input_methods))
	for p in players.get_children():
		# note: erase removes by value
		available_indices.erase(p.get_player_details()["input_method"])
	if len(available_indices) == 0:
		default_input_method = len(input_methods) - 1 # AI
	else:
		default_input_method = available_indices[0] # the smallest index not yet allocated

	player.setup(name, teams, input_methods, default_team, default_input_method)
	players.add_child(player)
	player.set_player_color(preset_colors[n] if n < preset_colors.size() else Color(255, 255, 255))
	player.connect('delete', self, '_remove_player', [player])

func _remove_player(player):
	players.remove_child(player)
	player.queue_free()



