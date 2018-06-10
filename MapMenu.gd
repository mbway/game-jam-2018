extends Control

var maps = [
	'res://LocalMultiplayer/MultiplayerMap.tscn',
	'res://LocalMultiplayer/MultiplayerMap_2.tscn',
	'res://LocalMultiplayer/MultiplayerMap_3.tscn'
]
var map_names = [
	'Map 1',
	'Map 2',
	'Map 3'
]

var current_map = 0

func change_selection(i):
	current_map = i % len(maps)
	$Title.text = map_names[current_map]

func create_map():
	var map_path = maps[current_map]
	print('loading ', map_path)
	return load(map_path).instance()

func _ready():
	change_selection(0)

func _process(delta):
	if Input.is_action_just_pressed('ui_left'):
		change_selection(current_map-1)
	elif Input.is_action_just_pressed('ui_right'):
		change_selection(current_map+1)
		
		