extends Control

signal back

var player_panel_scene = preload('res://MainMenu/PlayerPanel.tscn')

var maps = [
	{
		'path': 'res://Maps/UFO.tscn',
		'name' : 'UFO',
		'screenshot' : preload('res://Assets/MapScreenshots/UFO.png'),
	},
	{
		'path': 'res://Maps/Ship.tscn',
		'name' : 'Ship',
		'screenshot' : preload('res://Assets/MapScreenshots/Ship.png'),
	},
	{
		'path': 'res://Maps/Obelisk.tscn',
		'name' : 'Obelisk',
		'screenshot' : preload('res://Assets/MapScreenshots/Obelisk.png'),
	},
	{
		'path': 'res://Maps/Test.tscn',
		'name' : 'Test',
		'screenshot' : preload('res://Assets/MapScreenshots/Test.png'),
	},
	{
		'path': 'res://Maps/TestMap.tscn',
		'name' : 'Test Map',
		'screenshot' : preload('res://Maps/TestMap.png'),
	},
	{
		'path': 'res://Maps/SpaceMap.tscn',
		'name' : 'Space Map',
		'screenshot' : preload('res://Maps/SpaceMap.png'),
	}
]
var game_modes = [
	['TDM', 'Team Death Match'],
	['CTF', 'Capture The Flag'],
	['Overrule', 'Overrule']
]
var input_methods = [] # [{'type': globals.CONTROL_TYPE, 'name':#, 'index':(only with GAMEPAD)}]
var teams = ['Team 1', 'Team 2']

var selected_map = 0

var globals

# handles to UI nodes
var game_mode_dropdown
var map_screenshot
var map_title
var game_mode_options = []
var players


func _ready():
	globals = get_node('/root/globals')
	
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
	
	input_methods.append({'type' : globals.KEYBOARD_CONTROL, 'name' : 'Keyboard + Mouse'})
	for g in Input.get_connected_joypads():
		input_methods.append({'type' : globals.GAMEPAD_CONTROL, 'index' : g, 'name' : 'Gamepad %d' % g})
	input_methods.append({'type' : globals.AI_CONTROL, 'name' : 'AI'})
	
	# add a player for each non-AI input method
	for i in range(len(input_methods) - 1):
		_add_player()



# change the selected map index and reflect the change in the UI
func select_map(index):
	var n = len(maps)
	selected_map = index % n
	var map = maps[selected_map]
	map_title.text = '%s   (%d/%d)' % [map['name'], selected_map+1, n]
	map_screenshot.texture = map['screenshot']



func _on_StartButton_pressed():
	#TODO: validate that the configuration makes sense
	# - no two players have the same input
	# - there is at least one player
	
	var map_path = maps[selected_map]['path']
	globals.game_mode = game_modes[game_mode_dropdown.selected][0]
	
	var players_list = players.get_children()
	globals.player_data.clear()
	for i in range(len(players_list)):
		var p = players_list[i]
		
		var config = globals.PlayerConfig.new()
		config.num = i + 1 # 1-based
		config.name = p.find_node('PlayerName').text
		config.team = p.find_node('TeamOption').selected + 1 # 1-based
		
		var selected_input = input_methods[p.find_node('ControlOption').selected]
		config.control = selected_input['type']
		if config.control == globals.GAMEPAD_CONTROL:
			config.gamepad_id = selected_input['index']
		
		globals.player_data.append(config)
	
	if globals.game_mode == 'TDM':
		var options = game_mode_options[game_mode_dropdown.selected]
		globals.game_mode_details = {
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
	player.find_node('PlayerName').text = 'Player ' + str(players.get_child_count() + 1)
	player.find_node('DeleteButton').connect('pressed', self, '_remove_player', [player])
	var controls = player.find_node('ControlOption')
	for i in input_methods:
		controls.add_item(i['name'])
	
	# initially assign the lowest index into input_methods which has not yet been assigned to a player
	var available_indices = range(len(input_methods))
	for p in players.get_children():
		available_indices.erase(p.find_node('ControlOption').selected) # remove by value, not index
	if len(available_indices) == 0:
		controls.select(len(input_methods) - 1) # AI
	else:
		controls.select(available_indices[0]) # the smallest index not yet allocated
	
	var team = player.find_node('TeamOption')
	for t in teams:
		team.add_item(t)
	team.select(players.get_child_count() % len(teams))
	
	players.add_child(player)

func _remove_player(player):
	players.remove_child(player)
	player.queue_free()
	
	
	