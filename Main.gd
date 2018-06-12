extends Node

var game_mode = null

func _ready():
	randomize() # generate true random numbers

func _on_game_chosen(details):
	$MainMenu.hide()
	game_mode = details['game_mode']
	var map = load(details['map_path']).instance()
	map.name = 'World'
	add_child(map)



