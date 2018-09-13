extends Node

# for debugging purposes, this script can be used to jump right into a game without using the main menu

onready var G = globals

func _ready():
	randomize() # generate true random numbers
	G.log('QuickStart')

	G.player_data = [
		globals.PlayerConfig.new(1, 'Player 1', 1, globals.Control.KEYBOARD),
		#globals.PlayerConfig.new(2, 'Player 2', 2, globals.Control.GAMEPAD, 0),
		globals.PlayerConfig.new(2, 'Player 3', 2, globals.Control.AI)
	]
	G.game_mode = 'TDM'
	G.game_mode_details = {
		'max_lives' : 1
	}
	get_tree().change_scene('res://Maps/AIStressTest/AIStressTest.tscn')
