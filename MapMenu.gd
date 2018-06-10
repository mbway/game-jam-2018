extends Control

var maps = [
	{
		'path': 'res://LocalMultiplayer/MultiplayerMap.tscn',
		'name' : 'Test Map',
		'screenshot' : preload('res://Assets/Map1.png'),
		'type' : 'TDM'
	},
	{
		'path': 'res://LocalMultiplayer/MultiplayerMap_2.tscn',
		'name' : 'Ship',
		'screenshot' : preload('res://Assets/Map2.png'),
		'type' : 'CTF'
	},
	{
		'path': 'res://LocalMultiplayer/MultiplayerMap_3.tscn',
		'name' : 'Obelisk',
		'screenshot' : preload('res://Assets/Map3.png'),
		'type' : 'CTF'
	},
	{
		'path': 'res://LocalMultiplayer/MultiplayerMap_2_Overrule.tscn',
		'name' : 'Ship',
		'screenshot' : preload('res://Assets/Map2.png'),
		'type' : 'Overrule'
	},
	{
		'path': 'res://LocalMultiplayer/UFOMap.tscn',
		'name' : 'UFO',
		'screenshot' : preload('res://Assets/Map2.png'),
		'type' : 'TDM'
	}
]

var current_map = 0
var map_type

func change_selection(offset):
	assert offset != 0
	current_map = (current_map+offset) % len(maps)
	var attempts = 0
	while maps[current_map]['type'] != map_type:
		current_map = (current_map+offset) % len(maps)
		attempts += 1
		if attempts > len(maps):
			print('no maps with the type: %s' % map_type)
			return
	var map = maps[current_map]
	$Title.text = map['name']
	$Sprite.texture = map['screenshot']

func create_map():
	var map_path = maps[current_map]['path']
	print('loading ', map_path)
	return load(map_path).instance()

#func _ready():
	#change_selection(0)

func _process(delta):
	if Input.is_action_just_pressed('ui_left'):
		change_selection(-1)
	elif Input.is_action_just_pressed('ui_right'):
		change_selection(+1)


